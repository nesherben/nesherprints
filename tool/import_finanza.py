"""Importa el histórico del Excel (Finanza.ods) a la base de datos de la app.

Uso (cierra la app antes):
    python tool/import_finanza.py <Finanza.ods> <nesher_erp_v6.db>            # simulación
    python tool/import_finanza.py <Finanza.ods> <nesher_erp_v6.db> --apply    # escribe

- Hace una copia `<db>.bak-import-<fecha>` antes de escribir.
- Un pedido por fila con nombre en «ENCARGOS». Conserva el precio cobrado (I) y
  el coste de la hoja (Z) como `cost_override` (en pedidos en curso y cerrados).
- Estados: 0 Borrador, 1 En curso, 2 Completado (cobrado = precio).
- No toca el stock (el material de esos pedidos ya se gastó).
- Fechas que faltan o no son fechas («evento»…): se rellenan con la última
  fecha conocida de las filas anteriores (la hoja va en orden cronológico) y
  se deja constancia en las notas del pedido.
- Placas: la hoja solo da gramos y nº de placas totales, así que cada pedido
  tiene una placa «Importado» con esos gramos y las horas (si hay).
- Materiales: uno «Histórico» por cada €/kg distinto, con stock 0.
- Piezas: la tabla de materiales de la hoja (paquete, precio, unidad), stock 0.
- Cuadre: aborta (sin escribir) si el total cobrado de los completados no es
  el de la celda G3 de la hoja.
"""

import shutil
import sqlite3
import sys
import xml.etree.ElementTree as ET
import zipfile
from datetime import datetime

NS = {
    "t": "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
    "o": "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
    "x": "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
}
T = "{%s}" % NS["t"]
O = "{%s}" % NS["o"]
TAG = "Importado del Excel"

# Columnas (0 = A).
STATUS, DATE, ADVANCE, NAME, PRICE, GRAMS, PLATES, HOURS = 0, 1, 2, 4, 8, 9, 10, 11
ATTEMPTS, KIND, EUR_KG, PAINTED, COST = 12, 13, 14, 15, 25
EX_NAME, EX_PACK, EX_PRICE, EX_UNIT = 33, 34, 35, 36
HEADER_ROW = 3  # índice de la fila de cabeceras; los datos empiezan en la siguiente


def read_sheet(path):
    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read("content.xml"))
    table = next(root.iter(T + "table"))
    rows = []
    for row in table.iter(T + "table-row"):
        repeat = int(row.get(T + "number-rows-repeated", "1"))
        cells = []
        for c in row:
            if c.tag not in (T + "table-cell", T + "covered-table-cell"):
                continue
            n = min(int(c.get(T + "number-columns-repeated", "1")), 60)
            kind = c.get(O + "value-type")
            if kind in ("float", "percentage", "currency"):
                value = float(c.get(O + "value"))
            elif kind == "date":
                value = c.get(O + "date-value")
            elif kind == "string":
                value = "".join("".join(p.itertext()) for p in c.findall("x:p", NS))
            else:
                value = None
            cells.extend([value] * n)
        while cells and cells[-1] is None:
            cells.pop()
        rows.extend([cells] * (repeat if cells else min(repeat, 3)))
    return rows


def cell(row, i):
    return row[i] if i < len(row) else None


def num(v, default=0.0):
    return float(v) if isinstance(v, (int, float)) else default


def valid_date(v):
    if not isinstance(v, str):
        return None
    try:
        return datetime.strptime(v[:10], "%Y-%m-%d").strftime("%Y-%m-%d")
    except ValueError:
        return None


def build_plan(rows):
    orders, last_date = [], None
    for index, row in enumerate(rows[HEADER_ROW + 1 :], start=HEADER_ROW + 2):
        name = cell(row, NAME)
        if not isinstance(name, str) or not name.strip():
            continue
        status = int(num(cell(row, STATUS)))
        date = valid_date(cell(row, DATE))
        estimated = date is None
        if date:
            last_date = date
        orders.append(
            {
                "row": index,
                "name": name.strip(),
                "status": status,
                "date": date or last_date,
                "estimated": estimated,
                "price": num(cell(row, PRICE)),
                "advance": num(cell(row, ADVANCE)),
                "grams": num(cell(row, GRAMS)),
                "plates": int(max(num(cell(row, PLATES)), 0)),
                "hours": num(cell(row, HOURS)),
                "attempts": num(cell(row, ATTEMPTS), 1) or 1.0,
                "resin": cell(row, KIND) == "Resina",
                "eur_kg": num(cell(row, EUR_KG)),
                "painted": num(cell(row, PAINTED)) == 1,
                "cost": num(cell(row, COST)),
            }
        )
    # Las filas anteriores a la primera fecha usan la primera fecha conocida.
    first = next((o["date"] for o in orders if o["date"]), None)
    for o in orders:
        o["date"] = o["date"] or first

    extras = []
    for row in rows[HEADER_ROW + 1 :]:
        name = cell(row, EX_NAME)
        unit = cell(row, EX_UNIT)
        if isinstance(name, str) and name.strip() and isinstance(unit, (int, float)):
            extras.append((name.strip(), float(unit), num(cell(row, EX_PACK))))
    return orders, extras


DB_STATUS = {0: "Draft", 1: "In Progress", 2: "Completed"}


def apply_plan(db, orders, extras):
    materials = {}

    def material_id(resin, eur_kg):
        key = (resin, round(eur_kg, 4))
        if key not in materials:
            cur = db.execute(
                "INSERT INTO materials (name, color, type, cost_per_kg, stock_g) "
                "VALUES (?, ?, ?, ?, 0)",
                (
                    "Histórico (Excel)",
                    f"{eur_kg:g} €/kg".replace(".", ","),
                    "resin" if resin else "filament",
                    eur_kg,
                ),
            )
            materials[key] = cur.lastrowid
        return materials[key]

    for o in orders:
        closed = o["status"] == 2
        paid = o["price"] if closed else o["advance"]
        notes = f"{TAG} (fila {o['row']})."
        if o["estimated"]:
            notes += " Fecha estimada: la hoja no la tenía."
        if o["plates"] > 1:
            notes += f" {o['plates']} placas en la hoja."
        cur = db.execute(
            "INSERT INTO orders (name, price, paid_amount, date, status, "
            "is_painted, notes, attempts, cost_override, paint_level) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)",
            (
                o["name"],
                o["price"],
                paid,
                o["date"],
                DB_STATUS[o["status"]],
                1 if o["painted"] else 0,
                notes,
                o["attempts"],
                o["cost"] if o["status"] >= 1 else None,
            ),
        )
        if o["grams"] > 0:
            label = "Importado" if o["plates"] <= 1 else f"Importado ({o['plates']} placas)"
            db.execute(
                "INSERT INTO order_plates (order_id, name, grams, minutes, "
                "material_id, status) VALUES (?, ?, ?, ?, ?, ?)",
                (
                    cur.lastrowid,
                    label,
                    o["grams"],
                    o["hours"] * 60,
                    material_id(o["resin"], o["eur_kg"]),
                    "Success" if closed else "Pending",
                ),
            )
    for name, unit_price, _pack in extras:
        db.execute(
            "INSERT INTO extras (name, price, stock, unit) VALUES (?, ?, 0, '')",
            (name, unit_price),
        )
    return len(materials)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    apply = "--apply" in sys.argv
    if len(args) != 2:
        sys.exit(__doc__)
    ods, db_path = args

    rows = read_sheet(ods)
    orders, extras = build_plan(rows)
    gross_cell = cell(rows[2], 6)  # G3
    completed = [o for o in orders if o["status"] == 2]
    gross = sum(o["price"] for o in completed)
    cost = sum(o["cost"] for o in completed)
    by_status = {s: sum(1 for o in orders if o["status"] == s) for s in (0, 1, 2)}

    print(f"Pedidos a importar: {len(orders)} (borrador {by_status[0]}, "
          f"en curso {by_status[1]}, completados {by_status[2]})")
    print(f"Piezas (tabla de materiales de la hoja): {len(extras)}")
    print(f"Facturación bruta de completados: {gross:.2f} € (hoja G3: {gross_cell})")
    print(f"Coste de la hoja en completados: {cost:.2f} €  -> beneficio {gross - cost:.2f} €")
    print(f"Fechas estimadas: {sum(o['estimated'] for o in orders)} de {len(orders)}")
    print(f"Pagado por cobrar (en curso): "
          f"{sum(o['price'] - o['advance'] for o in orders if o['status'] == 1):.2f} €")
    if abs(gross - num(gross_cell)) > 0.005:
        sys.exit("NO CUADRA con G3: no se escribe nada.")
    print("Cuadre con G3: OK")

    if not apply:
        print("Simulación: no se ha escrito nada (usa --apply).")
        return

    db = sqlite3.connect(db_path)
    version = db.execute("PRAGMA user_version").fetchone()[0]
    if version < 6:
        sys.exit(f"La base de datos es v{version}: abre la app una vez para migrarla.")
    if db.execute("SELECT COUNT(*) FROM orders WHERE notes LIKE ?", (TAG + "%",)).fetchone()[0]:
        sys.exit("Ya se importó antes: no se importa dos veces.")
    db.close()

    backup = f"{db_path}.bak-import-{datetime.now():%Y%m%d-%H%M%S}"
    shutil.copy2(db_path, backup)
    print(f"Copia de seguridad: {backup}")

    db = sqlite3.connect(db_path)
    try:
        with db:
            n_materials = apply_plan(db, orders, extras)
            total = db.execute(
                "SELECT COALESCE(SUM(price),0) FROM orders WHERE notes LIKE ? AND status='Completed'",
                (TAG + "%",),
            ).fetchone()[0]
            assert abs(total - gross) < 0.005, "cuadre tras escribir"
    finally:
        db.close()
    print(f"Hecho: {len(orders)} pedidos, {n_materials} materiales, {len(extras)} piezas.")


if __name__ == "__main__":
    main()
