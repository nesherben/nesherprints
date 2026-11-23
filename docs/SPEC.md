# NesherPrints ERP — Especificación funcional

> Describe **cómo funciona la app hoy** (noviembre 2026), no cómo debería funcionar.
> Lo que parece un fallo o una decisión dudosa está en [Problemas conocidos](#9-problemas-conocidos) para decidirlo después.
> Si cambias una regla, actualiza este documento en el mismo commit.

## 1. Qué es

Aplicación de escritorio (Flutter, Windows principalmente; también Android) para llevar un pequeño negocio de **impresión 3D por encargo**. Un solo usuario, sin cuentas ni servidor: todo se guarda en un SQLite local.

Sirve para:
- **Presupuestar** un pedido a partir de sus placas de impresión, el material, las piezas extra y el pintado.
- **Seguir** los pedidos (estado, cobros, mermas).
- **Controlar el stock** de material (filamento/resina) y de piezas extra.
- **Ver la facturación** (bruto, neto, pendiente de cobro) en un panel.

UI en español. Moneda: euro (`€12.50`, siempre con punto y 2 decimales en pantalla; en los campos se acepta coma o punto).

## 2. Navegación

Barra lateral (`NavigationRail`) con 6 secciones y un botón fijo **"Nuevo Pedido"** abajo:

| # | Sección | Pantalla | Feature |
|---|---|---|---|
| 0 | Panel | `DashboardView` | `dashboard` |
| 1 | Inventario | `InventoryView` | `inventory` |
| 2 | Piezas | `ExtrasView` | `extras` |
| 3 | Pedidos | `OrdersView` | `orders` |
| 4 | Clientes | `ClientsView` | `clients` |
| 5 | Administración | `SettingsView` | `settings` |

Al cambiar de sección, la pantalla se reconstruye y recarga sus datos. La lista de pedidos la carga `MainLayout` y la comparten Panel y Pedidos; se recarga tras cada operación sobre pedidos.

## 3. Entidades

| Entidad | Tabla | Campos clave |
|---|---|---|
| Material (`PrintMaterial`) | `materials` | tipo (`filament`/`resin`), nombre/marca, color, coste €/kg, stock en g (ml) |
| Pieza extra (`Extra`) | `extras` | nombre, precio unitario €, stock (uds, puede ser negativo), unidad (no editable) |
| Cliente (`Client`) | `clients` | nombre, teléfono, email/Instagram, notas (no editables desde la UI) |
| Pedido (`Order`) | `orders` | cliente (opcional), nombre del proyecto, precio final, cobrado, fecha `YYYY-MM-DD`, estado, pintado (0/1), notas, **intentos** (1 = a la primera), **horas de pintura**, **colores**, **coste fijo** (solo pedidos importados del Excel) |
| Placa (`OrderPlate`) | `order_plates` | pedido, nombre, gramos, minutos, material, estado (`Pending`/`Success`/`Failed`) |
| Pieza en pedido | `order_extras` | pedido, pieza, cantidad, precio unitario en el momento de añadirla |
| Merma (`WasteRecord`) | `order_waste` | pedido, material, gramos perdidos, motivo, fecha (automática) |
| Consumo heredado | `order_items` | pedido, material, gramos. **La app ya no escribe aquí**; solo lo lee el panel |
| Ajustes | `settings` | clave → valor numérico |

### Estados del pedido

Se guardan y se muestran en inglés: `Draft`, `Reserved`, `In Progress`, `Completed`, `Shipped`, `Canceled`.

| Estado | Bloquea formulario | Botón "Completar" | Cuenta como ingreso | Cuenta como deuda |
|---|---|---|---|---|
| Draft | no | sí | no | no |
| Reserved | no | sí | no | sí |
| In Progress | no | sí | no | sí |
| Completed | **sí** | no | **sí** | sí |
| Shipped | **sí** | no | **sí** | sí |
| Canceled | no | no | no | no |

- A mano (formulario o menú rápido) se puede elegir cualquier estado **excepto `Completed`**, que solo se alcanza con la acción **Completar**.
- En el formulario, si el pedido ya está `Completed`, la opción aparece en el desplegable (aunque el formulario está bloqueado).

## 4. Pantallas y reglas

### 4.1 Pedidos (`features/orders`)

**Listado** (`OrdersView` + `OrderDataTable`)
- Buscador por nombre de proyecto (contiene, sin distinguir mayúsculas).
- Filtro por estado ("Todos" o un estado).
- Orden por columna: ID, Proyecto, Estado (texto), Finanzas (precio). Sin orden elegido: ID descendente.
- "Limpiar Filtros" aparece si hay búsqueda, filtro u orden activos.
- Columnas:
  - **ID / Fecha**.
  - **Proyecto**, con el nombre del cliente si tiene.
  - **Estado**: etiqueta con menú de cambio rápido.
  - **Finanzas**: Total, Pagado y "Falta" si queda deuda. Va en verde con ✓ si está saldado, es decir completado o con lo pendiente ≤ 0.
  - **Detalles**: "Pintado", nº de placas, merma en % y nombres de las placas.
  - **Acciones**.
- Merma en %: `gramos perdidos / gramos teóricos × 100`, sin límite. Sin gramos teóricos se divide entre 1 g. Color: > 30 % rojo, > 10 % naranja, el resto verde.
- **Acciones por fila:**
  - **Completar** (solo si `canComplete`). Pide confirmación. Pone estado `Completed`, cobrado = precio y **resta del inventario los gramos de todas las placas**.
  - **Editar**: abre el formulario.
  - **Merma**: abre el diálogo de merma.
  - **Eliminar**: pide confirmación. Devuelve al stock las piezas extra y borra el pedido.

**Formulario** (`OrderFormDialog`, se abre desde "Nuevo Pedido" o desde "Editar")
1. **Cliente** (opcional), con botón para crear uno nuevo sin salir.
2. **Nombre del proyecto** y **estado**.
3. **Placas**: añadir o quitar. Cada placa tiene nombre (por defecto "Placa N"), material (por defecto el primero de la lista), gramos y minutos. Botón para dar de alta un material nuevo y asignarlo a la placa.
4. **Piezas extra**: contador −/+ por cada pieza del inventario.
5. **Finanzas**:
   - nº de placas (automático);
   - intentos (por defecto 1);
   - casilla de pintura, sus horas (por defecto 1) y los colores (por defecto 0);
   - coste de fabricación y precio recomendado, con "Aplicar" para copiarlo al precio;
   - precio final, con color de semáforo;
   - pagado/adelanto (por defecto 0.00).
- Si el pedido está bloqueado (`Completed`/`Shipped`), todo es de solo lectura y no se puede guardar.
- Al **crear**: se guarda el pedido con sus placas y piezas. Se **resta el stock de las piezas**, pero no el del material: el material se resta al completar.
- Al **editar**:
  - si la lista de placas no está vacía, se **reemplazan todas las placas** (conservan su id y su estado);
  - si la lista de piezas no está vacía, se devuelven al stock las anteriores y se aplican las nuevas;
  - si alguna de las dos listas está vacía, esa parte **no se toca**.

**Merma** (`WasteDialog`)
- Se elige la placa (por defecto la primera) y el % que llegó a imprimirse (deslizador de 5 en 5, por defecto 100 %).
- Gramos perdidos = gramos de la placa × %. Se guarda en `order_waste` y **se restan del stock del material**.
- Motivo opcional. Si se deja vacío: "Fallo al N% en <placa>".
- Si el pedido no tiene placas, solo se muestra un aviso.

### 4.2 Calculadora de precios (`PricingCalculator`)

Transcrita del Excel `Finanza.ods` (detalle y casos reales en [`EXCEL_FORMULAS.md`](EXCEL_FORMULAS.md)); los tests usan pedidos reales de la hoja.

Entradas: placas (gramos, minutos y material con su €/kg y tipo), intentos, pintura (sí/no, horas y colores), piezas elegidas y los ajustes.

```
mat    = Σ gramos/1000 × €/kg de su material
horas  = Σ minutos / 60            n = nº de placas      hPlaca = horas / n
tarifa = media de (resina ? tarifaResina : tarifaFilamento) de las placas
recargo = max(0, (n−1) × tarifa × (1 + 0,1·(n−1)))        # la 1.ª placa no paga
seg    = 1 + margenSeguridad/100
pintura = pintado ? (horasPintura × €/h + colores × costeColor) × seg : 0

COSTE = max(0, (mat × intentos + horas × kWh × intentos + recargo) × seg + pintura) + piezas

luz     = n × (hPlaca ≤ 12 ? hPlaca : 12 + 15·ln(hPlaca/12)) × kWh      # se amortigua
largo   = hPlaca ≤ 8 ? 1 : 1 + 0,085·ln(hPlaca/8)                       # impresión larga
RECOMENDADO = (mat×2 + luz + recargo) × largo × (2 + margenBeneficio/100)
              + pintura + piezas × (1 + margenBeneficio/100)
```

- Los intentos solo afectan al coste, no al precio recomendado.
- Las piezas se suman al coste a su precio unitario y al precio con el margen de beneficio (decisión provisional; en el Excel se sumaban a mano).
- Con varios materiales, el recargo usa la media de tarifas de las placas (el Excel solo admite un tipo por pedido).
- Diferencia con el Excel: la hoja multiplica por `1 + (S+100)/100`, que con S = 0,15 vale 2,0015 (el 15 % no se aplica). La app usa `2 + margen/100` = 2,15.

**Semáforo del precio final** (frente al coste y al recomendado):
- **neutro** si el precio o el coste son ≤ 0;
- **verde** si precio ≥ recomendado;
- **naranja** si coste < precio < recomendado;
- **rojo** si precio ≤ coste.

### 4.3 Panel (`features/dashboard`, `FinanceSummary`)

- **Ingresos brutos**: Σ precio de los pedidos `Completed` + `Shipped`.
- **Beneficio neto**: bruto − coste de material según `order_items` (tabla heredada) − coste de **todas** las mermas registradas (gramos × €/kg actual del material).
- **Pendiente de cobro**: Σ (precio − cobrado) > 0 de los pedidos que no son `Draft` ni `Canceled`.
- **Histórico mensual** (barras): bruto y neto por mes (`YYYY-MM` de la fecha del pedido), solo con ingresos. El neto mensual no descuenta mermas.
- **Distribución** (tarta): % de pedidos por estado, con leyenda.

### 4.4 Inventario (`features/inventory`)

- Tabla de materiales: tipo (chip Resina/Filamento), nombre, color, €/kg, stock. Orden: resinas primero y después por nombre.
- Stock en rojo si es < **200 g**; si no, en verde.
- Añadir/editar con un diálogo: tipo, nombre/marca, color, €/kg y stock.
- **Eliminar sin confirmación.**

### 4.5 Piezas extra (`features/extras`)

- Lista con nombre, precio unitario y stock.
- **Alta/edición por paquete**:
  - se introducen las unidades y el precio total;
  - precio unitario = total / unidades (o el total si no hay unidades);
  - al editar, el formulario propone total = precio unitario × stock y **las unidades sustituyen al stock actual**.
- **Sumar unidades**: se introducen las unidades y el precio pagado por ellas.
  - Nuevo precio unitario = media ponderada: `(precio × stock + total) / (stock + unidades)`.
  - Si el stock resultante es ≤ 0, se mantiene el precio.
  - Solo se puede aplicar con unidades > 0 y total ≥ 0.
- Eliminar con confirmación.

### 4.6 Clientes (`features/clients`)

- Rejilla de tarjetas (3 columnas) con nombre, teléfono y email, ordenada por nombre.
- Alta/edición: nombre/alias, teléfono (WhatsApp) y email/Instagram, todos opcionales.
  - Si todo está vacío, se cierra sin guardar.
  - Si falta el nombre, se usa el teléfono o, si tampoco hay, el email.
  - Se recortan los espacios.
- No se pueden borrar clientes.

### 4.7 Administración (`features/settings`)

| Ajuste | Clave en BD | Por defecto |
|---|---|---|
| Margen de beneficio (%): el precio recomendado se multiplica por 2 + margen | `margen_beneficio` | 15 |
| Margen de seguridad del coste (%) | `margen_seguridad` | 15 |
| Coste de luz (€/hora de impresión) | `coste_kwh` | 0,0375 |
| Recargo por placa extra, filamento (€) | `tarifa_placa_filamento` | 0,5 |
| Recargo por placa extra, resina (€) | `tarifa_placa_resina` | 1,5 |
| Coste de pintado (€/hora) | `coste_hora_pintado` | 8 |
| Coste por unidad de color (€) | `coste_unidad_color` | 1/90 |
| Objetivo de beneficio (€) | `objetivo_beneficio` | 5000 |

- Un valor no numérico guarda el valor por defecto. Si falta una clave, guardar la crea.
- Afectan a los cálculos desde ese momento: el precio guardado en un pedido no cambia.
- `coste_placa_extra` (v1-v2) está obsoleta: la fila se conserva pero no se usa.

## 5. Movimientos de stock (resumen)

| Acción | Material (`materials.stock_g`) | Piezas (`extras.stock`) |
|---|---|---|
| Crear pedido | — | − cantidades |
| Editar pedido con piezas | — | + anteriores, − nuevas |
| Completar pedido | − gramos de todas sus placas | — |
| Registrar merma | − gramos perdidos | — |
| Borrar pedido | — (no se devuelve nada) | + cantidades |
| Sumar unidades a pieza | — | + unidades |

Todas estas operaciones se hacen en una única transacción.

## 6. Base de datos

- Archivo `nesher_erp_v6.db` en la carpeta de bases de datos del sistema. El "v6" del nombre es histórico; la versión del esquema es `PRAGMA user_version = 3`.
- El esquema está definido en un solo sitio: `lib/core/database/db_schema.dart`.
  - `onCreate`: crea todas las tablas e inserta los 3 ajustes.
  - `onUpgrade`: asegura todas las tablas y aplica migraciones incrementales con `if (oldVersion < N)`. La v2 añadió clientes, placas y piezas. La v3 añadió a `orders` intentos, horas de pintura, colores y coste fijo, e insertó los ajustes de las fórmulas del Excel; los ajustes `margen_beneficio` (45) y `coste_hora_pintado` (15) se pasan a 15 y 8 solo si conservan su valor por defecto antiguo.
  - `onOpen`: `CREATE TABLE IF NOT EXISTS` de todas las tablas como red de seguridad. No modifica datos.
- `PRAGMA foreign_keys` **no** está activado, así que los `ON DELETE CASCADE` no actúan.
- Los valores de estado se guardan como texto en inglés. No se pueden renombrar sin migrar los datos.

## 7. Arquitectura

Ver [`CLAUDE.md`](../CLAUDE.md) para el mapa de carpetas y las convenciones.

## 8. Pruebas

- `test/features/repositories_test.dart`: repositorios sobre SQLite en memoria (stock, completar, borrar, mermas, ajustes, migración v1→v2).
- `test/features/orders/pricing_calculator_test.dart`: fija la fórmula de precio actual.
- `test/features/dashboard/finance_summary_test.dart`, `order_test.dart` y `extras_and_clients_test.dart`: reglas puras.

## 9. Problemas conocidos

Comportamiento actual que probablemente no es el deseado. **No se ha cambiado** en el refactor para no alterar resultados. Hay que decidir cada uno por separado.

| # | Dónde | Qué pasa | Impacto |
|---|---|---|---|
| P1 | Panel, beneficio neto | El coste de material sale de `order_items`, que ya no se escribe, así que hoy es 0. El neto solo descuenta mermas. | El neto se sobreestima. El coste real de las placas ya existe (`OrderSummary.materialCost`). |
| P2 | ~~Recargo acumulativo por placa~~ | **Resuelto en v3**: la calculadora sigue el Excel (recargo no acumulativo). | — |
| P3 | Editar pedido | El formulario no carga las piezas extra que ya tiene el pedido (aparecen a 0). Si no se toca nada se conservan; si se añade alguna, **sustituyen** a las anteriores. Tampoco se pueden quitar todas. | Fácil perder o duplicar piezas sin darse cuenta. |
| P4 | ~~Horas de pintura no guardadas~~ | **Resuelto en v3**: se guardan con el pedido, junto con los colores y los intentos. | — |
| P5 | Borrar pedido | No se borran sus placas ni sus mermas (no hay `foreign_keys`). Las mermas huérfanas **siguen restando** en el neto. | Datos huérfanos y neto alterado. |
| P6 | Completar | Resta los gramos de todas las placas aunque alguna haya fallado y ya tenga merma registrada. | El material de una placa fallida se descuenta dos veces. |
| P7 | Estados | El cambio rápido permite pasar un pedido `Completed` a otro estado, y pasar a `Shipped` sin completar, así que no se resta material. | Stock y cobros incoherentes. |
| P8 | Inventario | Borrar material no pide confirmación y no comprueba si lo usan placas. | Placas con material inexistente: su coste deja de contar. |
| P9 | Piezas | Editar una pieza sobrescribe el stock con "unidades por paquete". | Se pierde el stock real. |
| P10 | Validación | Se pueden guardar materiales, pedidos y piezas sin nombre o con valores negativos. Un pedido con una placa sin material falla al guardar (NOT NULL). | Datos basura o error sin mensaje. |
| P11 | UI | Los estados se muestran en inglés en una UI en español. | Inconsistencia visual. |
| P12 | Errores | Las operaciones de BD no muestran ningún mensaje si fallan. | Fallos silenciosos. |
| P13 | ~~Ajustes~~ | **Resuelto**: guardar crea la clave si falta. | — |
