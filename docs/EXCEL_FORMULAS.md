# Fórmulas del Excel (`Finanza.ods`) — referencia histórica

> **Desde el 24-nov-2026 la app ya no usa estas fórmulas.** El usuario decidió olvidar el Excel y pasar a un modelo más simple y fácil de configurar (ver [`SPEC.md`](SPEC.md) §4.2). Este documento se conserva para **importar los datos históricos** de la hoja (columnas, estados, lotes) y para entender los costes y precios antiguos. Las secciones 2–4 describen las fórmulas de la hoja, no las de la app.

> Transcripción de la hoja de cálculo con la que se llevan hoy los pedidos. Es la **fuente de verdad** de los cálculos: la app debe acabar dando los mismos números.
> Verificado: recalculando las filas 139, 142, 143, 144 y 145 con estas fórmulas se obtiene exactamente lo que guarda la hoja.
> Pendiente de decisiones: ver [Preguntas abiertas](#6-preguntas-abiertas).

## 1. Una fila = un pedido

| Col | Nombre en la hoja | Significado | Equivalente en la app hoy |
|---|---|---|---|
| A | commited | Estado: `0` no confirmado, `1` confirmado (falta cobrar), `2` terminado y cobrado | `OrderStatus` (6 estados) |
| B | fecha | Fecha del pedido | `Order.date` |
| C | adelanto | Cobrado a cuenta | `Order.paidAmount` |
| D | resto | Pendiente: `A=1 ? I − C : 0` | `Order.pendingAmount` |
| E | ENCARGOS | Nombre del proyecto | `Order.name` |
| F | pvpr | **Precio recomendado** (fórmula §2) | precio sugerido |
| G | gasto | = Z | coste |
| H | resumen | = AB | — |
| I | PRECIO | Precio final cobrado | `Order.price` |
| J | — | **Gramos totales** (a menudo suma de placas: `=137+92`) | Σ gramos de las placas |
| K | placas | Nº de placas | nº de `OrderPlate` |
| L | tiempo (h) | **Horas totales** de impresión | Σ minutos / 60 (no se usa en el precio) |
| M | INTENTOS | Multiplicador de material por fallos (1 = a la primera, 1,3 = +30 %) | **no existe** |
| N | tipo | `Filamento` / `Resina` | `MaterialKind` por material |
| O | COSTE (€/kg) | Coste del material (uno por pedido) | €/kg de cada placa |
| P | Pintado? | 0/1 | `Order.isPainted` |
| Q | horas pintado | Horas de pintura | se pide pero **no se guarda** |
| R | colores | Pinturas usadas (cada una cuesta 1/90 €; nota: "18 ml × 50") | **detalle de pintura**: pocos / normal / muchos (ver §4) |
| S | margenes | % (15 % en los pedidos recientes, 12,5 % antes) | margen de beneficio (45 % por defecto) |
| T | Trabajo €/h pintado | 8 € | coste pintado/hora (15 € por defecto) |
| U | Coste pintado | fórmula §4 | coste de pintura |
| Z | gastos | **Coste real** (fórmula §3) | coste de fabricación |
| AA | beneficios | `A=0 ? 0 : I − Z` | — |
| AB | teoricos | `A=0 ? 0 : I − Z + U` (beneficio contando la pintura como ingreso propio) | — |

Constante global: **C3 coste luz = 0,25 kW × 0,15 €/kWh = 0,0375 €/h**.

## 2. Precio recomendado (F) — versión vigente (filas 136+)

```
hPlaca   = L / max(1, K)                                   # horas medias por placa
hLuz     = hPlaca ≤ 12 ? hPlaca : 12 + 15·ln(hPlaca/12)    # se amortigua a partir de 12 h
luz      = K · hLuz · 0,0375
tarifaPlaca = (Resina ? 1,5 : 0,5)
recargoPlacas = max(0, (K−1) · tarifaPlaca · (1 + 0,1·(K−1)))   # la 1.ª placa no paga
factorLargo = hPlaca ≤ 8 ? 1 : 1 + 0,085·ln(hPlaca/8)      # impresiones largas

F = A=0 ? 0 :
    ( (J·O/1000)·2 + luz + recargoPlacas ) · factorLargo · (1 + (S+100)/100) + U
```

Observaciones:
- El material se cuenta **×2** fijo (no usa M).
- `(1 + (S+100)/100)` con S = 0,15 vale **2,0015**: en la práctica es "×2" y S casi no influye (ver pregunta Q1).
- El recargo por placa **no es acumulativo** (a diferencia de la app, problema P2 de SPEC.md).

Ejemplo (fila 142 "espadon"): J=1640 g, K=7, L=59 h, M=1, Filamento, O=9 €/kg, S=15 %, sin pintar → **F = 73,44 €** (se cobró 80 €).

## 3. Coste real (Z) — versión vigente (filas 139+)

```
Z = A=0 ? 0 :
    max(0, ( J·O·M/1000 + L·M·0,0375 + (K−1)·tarifaPlaca·(1 + 0,1·(K−1)) ) · (1+S) + U )
```

- Aquí sí se usan los intentos M (material y luz), y la luz es lineal (sin amortiguar).
- S actúa como **margen de seguridad sobre el coste**, no como margen de beneficio.
- Fila 142 → **Z = 25,04 €**.

Versiones anteriores (filas 6–135): sin luz y con recargo de 1 € por placa extra; algunas filas suman piezas de la tabla de materiales a mano (`+AK8`, `+9*AK13`…) o son lotes (filas 62–69, multiplican por una cantidad en AC/AD).

## 4. Coste de pintura (U)

```
U = P · (Q·T + R/90) · (1 + S)
```

**En la app** los colores (`R`) se sustituyen por tres modos de *detalle* — más detalle, más material de pintura; el trabajo ya se mide en las horas `Q`:

| Modo | Colores | Material (€) por defecto | Colores típicos en la hoja |
|---|---|---|---|
| Pocos | ≤ 4 | 3/90 = 0,033 | 1, 3, 4, 4 |
| Normal | 5–10 | 9/90 = 0,10 | 8, 8, 10, 10 |
| Muchos | > 10 | 13/90 = 0,144 | 12, 14, 14 |

Los tres importes son ajustes editables. Son céntimos (con 1/90 € por color, 14 colores cuestan 0,16 €): el peso de la pintura está en las horas × 8 €/h, así que el modo apenas cambia el precio salvo que se suba su importe. Al importar un pedido, sus colores se convierten al modo que les corresponde (4 → pocos, 5–10 → normal, > 10 → muchos).

## 5. Resúmenes

| Celda | Qué es | Fórmula |
|---|---|---|
| G3 bruto | Ingresos de pedidos terminados | Σ I donde A=2 |
| F3 "gasto tiempo" | Beneficio real | Σ AA donde A=2 |
| E3 ganancias acumuladas | Beneficio "teórico" (con pintura) | Σ AB donde A=2 |
| H3 | % de beneficio | E3 / G3 |
| I3 / J3 | Objetivo (5.000 €) y si se ha alcanzado | E3 ≥ I3 |
| AC/AE/AF (por mes) | Beneficio neto, bruto y ratio mensual | Σ AB, Σ I (A=2) por rango de filas del mes; AC/AE |

Tabla de **materiales/piezas** (AH–AK): nombre, unidades del paquete, precio del paquete, precio unitario = precio/paquete. Equivale a las **Piezas (Extras)** de la app. En la hoja se suman a mano al coste Z del pedido.

La hoja tiene además un presupuesto personal mensual (ingresos, gastos fijos y beneficio medio de encargos). No forma parte de este documento.

## 6. Qué queda de este documento

- La **migración de datos** del Excel a la app (pedidos y materiales históricos) sigue pendiente: al importar, cada pedido conservará su precio cobrado y su coste tal como estaban en la hoja (`cost_override`), sin recalcular con el modelo nuevo. Los estados 0/1/2 se mapearán a Borrador / En curso / Completado, y los colores de pintura ya no se usan.
- Todas las decisiones sobre fórmulas (multiplicador ×2,15, material por placa, luz amortiguada, detalle de pintura…) quedaron **reemplazadas por el modelo simple** de `SPEC.md` §4.2.
