# NesherPrints ERP — Especificación funcional

> Describe **cómo funciona la app hoy** (24-nov-2026). Fórmulas del Excel y plan de migración: [`EXCEL_FORMULAS.md`](EXCEL_FORMULAS.md). Mapa del código: [`../CLAUDE.md`](../CLAUDE.md).
> Si cambias una regla, actualiza este documento en el mismo commit.

## 1. Qué es

Aplicación de escritorio (Flutter, Windows principalmente; también compila para Android) para llevar un pequeño negocio de **impresión 3D por encargo**. Un solo usuario, sin cuentas ni servidor: todo se guarda en un SQLite local.

Sirve para:
- **Presupuestar** un pedido a partir de sus placas, material, piezas extra, pintura e intentos, con las fórmulas del Excel del usuario.
- **Seguir** los pedidos (estado, cobros, mermas).
- **Controlar el stock** de material (filamento/resina) y de piezas extra.
- **Ver el negocio**: facturado, beneficio real, cobros pendientes y avance hacia el objetivo.

UI en español, tema oscuro. Moneda: euro (`€12.50`; en los campos se acepta coma o punto).

## 2. Navegación

| # | Sección | Atajo | Pantalla |
|---|---|---|---|
| 0 | Panel | `Ctrl+1` | `DashboardView` |
| 1 | Inventario | `Ctrl+2` | `InventoryView` |
| 2 | Piezas | `Ctrl+3` | `ExtrasView` |
| 3 | Pedidos | `Ctrl+4` | `OrdersView` |
| 4 | Clientes | `Ctrl+5` | `ClientsView` |
| 5 | Administración | `Ctrl+6` | `SettingsView` |

- `Ctrl+N`: nuevo pedido desde cualquier sección. `Ctrl+F`: buscar (en Pedidos). `Ctrl+S`: guardar (formulario de pedido y Administración).
- **Ventana ancha (≥ 1100 px):** barra lateral extendida con logotipo, botón «Nuevo pedido» y etiquetas. **Media:** barra lateral compacta. **Estrecha (< 720 px):** barra de navegación inferior y botón flotante «Nuevo pedido».
- Cambiar de sección reconstruye la pantalla (recarga sus datos) con un fundido suave. La lista de pedidos la carga `MainLayout` y la comparten Panel y Pedidos.
- Si se guarda un pedido desde una sección que no es Panel ni Pedidos (por ejemplo desde Piezas), esa pantalla se recarga para no mostrar stock viejo.

## 3. Entidades

| Entidad | Tabla | Campos clave |
|---|---|---|
| Material (`PrintMaterial`) | `materials` | tipo (`filament`/`resin`), nombre/marca, color, coste €/kg, stock en g (ml) |
| Pieza extra (`Extra`) | `extras` | nombre, precio unitario €, stock (uds; puede quedar negativo), unidad (no editable) |
| Cliente (`Client`) | `clients` | nombre, teléfono, email/Instagram, notas (no editables desde la UI) |
| Pedido (`Order`) | `orders` | cliente (opcional), proyecto, precio final, cobrado, fecha `YYYY-MM-DD`, estado, pintado, notas, **intentos**, **detalle de pintura**, **coste fijo** (solo importados) |
| Placa (`OrderPlate`) | `order_plates` | pedido, nombre, gramos, minutos, material, estado (`Pending`/`Success`/`Failed`) |
| Pieza en pedido | `order_extras` | pedido, pieza, cantidad, precio unitario **registrado** al añadirla |
| Merma (`WasteRecord`) | `order_waste` | pedido, material, gramos perdidos, motivo, fecha |
| Consumo heredado | `order_items` | ya no se usa (se conserva la tabla) |
| Ajustes | `settings` | clave → valor numérico |

### Estados del pedido

Se guardan en inglés (`dbValue`, no cambiar) y se muestran en español.

| Estado (guardado → mostrado) | Formulario | Botón «Completar» | Ingreso | Deuda | Cambios rápidos permitidos |
|---|---|---|---|---|---|
| `Draft` → Borrador | editable | sí | no | no | Reservado, En curso, Cancelado |
| `Reserved` → Reservado | editable | sí | no | sí | Borrador, En curso, Cancelado |
| `In Progress` → En curso | editable | sí | no | sí | Borrador, Reservado, Cancelado |
| `Completed` → Completado | **solo lectura** | no | **sí** | sí | **solo Enviado** |
| `Shipped` → Enviado | **solo lectura** | no | **sí** | sí | ninguno |
| `Canceled` → Cancelado | editable | **no** | no | no | Borrador, Reservado, En curso |

- **Completado** solo se alcanza con la acción «Completar» (descuenta material); **Enviado** solo desde Completado. Un pedido cerrado no se puede reabrir ni editar (el repositorio lo rechaza con un mensaje).
- Un pedido nuevo no puede nacer completado ni enviado.

## 4. Pantallas y reglas

### 4.1 Pedidos (`features/orders`)

**Listado** (`OrdersView` + `order_list.dart`)
- Búsqueda por proyecto, cliente, nº de pedido (`#12`) o nombre de placa. `Ctrl+F` enfoca el buscador.
- Filtros en chips con contador: Todos, **Por cobrar** (deuda > 0 en pedidos con deuda) y uno por estado. «Limpiar filtros» aparece si hay alguno activo.
- Orden por columna (ID/fecha, proyecto, estado, finanzas) pulsando la cabecera; en estrecho, menú «Ordenar por» (incluye «pendiente de cobro»). Sin elegir: más reciente primero.
- Filas virtualizadas (válidas para cientos de pedidos). **Ancho (≥ 880 px del listado):** columnas ID/fecha, proyecto + cliente, estado, finanzas, detalles, acciones. **Estrecho:** tarjetas apiladas.
- **Finanzas**: total; «Cobrado» en verde con ✓ si está saldado (completado o pendiente ≤ 0); si no, «Pagado X · Falta Y».
- **Detalles**: nº de placas, «Pintado», merma en % (rojo > 30 %, ámbar > 10 %, verde) y nombres de las placas. Merma % = gramos perdidos / gramos de las placas × 100, sin límite.
- **Acciones**: Completar (solo si procede), Editar/Ver y menú ⋮ (Registrar merma, Duplicar, Eliminar). Tocar la fila abre el pedido.
- **Completar** pide confirmación indicando los gramos aproximados que se descontarán. **Eliminar** pide confirmación y explica qué ocurre. Toda acción fallida muestra un aviso con el motivo.
- Estados vacíos: sin pedidos («Crear el primer pedido») y sin resultados («Limpiar filtros»).

**Formulario** (`OrderFormDialog`: nuevo, editar o duplicar)
- Dos columnas en ancho (datos a la izquierda con scroll, **resumen de precio fijo** a la derecha); una columna en estrecho.
- **Datos**: nombre del proyecto, estado (según §3), cliente opcional con alta rápida.
- **Placas**: nombre, material (desplegable con €/kg), gramos y minutos; alta rápida de material; duplicar/quitar placa; la placa nueva hereda el material de la anterior. Avisa si los gramos superan el stock del material y muestra el coste de material de la placa.
- **Piezas extra**: contador −/+ por pieza con su precio y stock; avisa si se piden más de las que hay. Al editar se cargan las piezas del pedido con su **precio registrado**.
- **Producción**: intentos (decimal, 1 = a la primera) y pintura con su detalle (simple, normal o detallada).
- **Resumen**: nº de placas, tiempo y gramos; desglose (material, máquina, placas, pintura, piezas), nota de intentos y aviso si se aplica el precio mínimo; **coste real**; **precio recomendado** con «Aplicar»; precio final con valoración en texto (verde «Beneficio X (+Y % sobre el coste)», ámbar «Por debajo del recomendado», rojo «Pierdes X»); cobrado con atajos `0 € / 50 % / Todo` y «Falta por cobrar».
- **Validación** (`OrderRules.validateForm`): nombre obligatorio, al menos una placa, cada placa con material, gramos > 0 y ≤ 5000, tiempo entre 0 y 10 días, precio ≥ 0 (0 vale para regalos), cobrado entre 0 y el precio, intentos > 0. Los errores se muestran en el pie y se actualizan al corregir.
- **Guardado**: asíncrono; el diálogo no se cierra hasta que se guarda. Si falla, se queda abierto con el error y sin perder lo escrito. `Ctrl+S` guarda.
- **Notas** del pedido editables. Cerrar con cambios sin guardar (botón o «atrás») pide confirmación.
- Si el pedido está cerrado: banner informativo, todo en solo lectura y sin botón de guardar.
- **Duplicar**: pedido nuevo en Borrador, con las placas (sin ids) y piezas del original, nombre «… (copia)», fecha de hoy y cobrado 0.
- Al **crear**: se guardan pedido, placas y piezas; se **resta el stock de las piezas** (no el del material). Al **editar**: las placas y piezas se reemplazan por las del formulario (lista vacía = borrar); las piezas anteriores se devuelven al stock y se aplican las nuevas, conservando el precio registrado de las que ya estaban.

**Merma** (`WasteDialog`): se elige la placa y el % que llegó a imprimirse (de 5 en 5); gramos = gramos de la placa × %. Se guarda y **se resta del material**. Motivo opcional («Fallo al N % en <placa>» por defecto). No se puede registrar una merma de 0 g.

### 4.2 Calculadora de precios (`PricingCalculator`)

Modelo simple: se suman los costes reales y se aplica un margen. Cada concepto se entiende y se configura con un solo número.

```
material = Σ gramos/1000 × €/kg de su material × intentos
máquina  = horas de impresión × (0,25 kW × €/kWh + desgaste €/h) × intentos
placas   = nº de placas × coste por placa
piezas   = Σ precio × cantidad

COSTE       = material + máquina + placas + piezas
SIN PINTAR  = max(precio mínimo, COSTE × (1 + margen/100))
RECOMENDADO = SIN PINTAR + importe de pintura del nivel (si se pinta)
```

- **Pintura**: no se cobra por horas ni como múltiplo. Según el **detalle de la figura** (Simple / Normal / Detallada) se suma un importe fijo configurable (por defecto +20 €, +60 € y +100 €, calibrados con lo cobrado de más en las piezas pintadas del histórico). No depende del peso (un múltiplo del precio sin pintar sobrevaloraba las piezas grandes y lisas e infravaloraba las pequeñas y detalladas) y no es coste: el coste real no cambia. El nivel se guarda en el pedido (`paint_level`: 0 simple, 1 normal, 2 detallada).

- **Intentos** (por pedido, 1 = a la primera): reimpresiones por fallos; multiplican material y máquina, no el resto.
- La potencia de la impresora (0,25 kW de media) es una constante (`PricingConstants.printerKw`); con 0,15 €/kWh son unos 0,04 €/h de luz, más 0,10 €/h de desgaste = 0,1375 €/h.
- Sin coste (sin placas ni piezas) no hay precio recomendado (ni mínimo).
- **Semáforo** del precio final frente al coste y al recomendado: neutro si precio o coste ≤ 0; bueno si precio ≥ recomendado; bajo si coste < precio < recomendado; pérdida si precio ≤ coste.
- Los valores por defecto se calibraron con 9 pedidos reales cobrados: con ellos el recomendado queda a ±10 % en la mayoría de piezas medianas y grandes (espadón: coste 29,87 €, recomendado 74,68 €, cobrado 80 €) y por debajo en las pequeñas, donde actúa el precio mínimo. Ver el histórico de fórmulas en [`EXCEL_FORMULAS.md`](EXCEL_FORMULAS.md).

### 4.3 Panel (`features/dashboard`)

- **Indicadores**: Facturado (suma de pedidos completados o enviados), **Beneficio** (facturado − coste real; con su margen %), **Pendiente de cobro** (deuda de pedidos que no son borrador ni cancelados) y **Objetivo** (beneficio / objetivo configurable, con barra de progreso).
- **Coste real** de cada pedido cerrado: su coste fijo (`costOverride`). Se **congela al completar** (`CostFreezer`, con los precios y ajustes de ese momento) y los pedidos importados traen el de la hoja, así que cambiar un €/kg o un margen no altera el beneficio histórico. Solo si un pedido cerrado no tuviera coste fijo se recalcularía (`OrderCosting`).
- Gráfica de barras de facturado y beneficio por mes (con scroll si hay muchos meses y tooltips), anillo de pedidos por estado, **detalle mensual** (pedidos, facturado, beneficio, margen; el mes más reciente primero) y lista de **pendientes de cobro** con su antigüedad.
- Las **mermas** no se restan del beneficio (ya van en los intentos); se muestran como nota informativa con su coste.

### 4.4 Inventario (`features/inventory`)

- **Resina = tanque**: tarjeta con un tanque animado (nivel = gramos / capacidad; 5 kg o el siguiente kilo entero), kilos, gramos, precio medio y valor. **Añadir resina** pide gramos y precio de la remesa y promedia el precio por kilo con lo que había (`ResinBlend`, atómico en `MaterialRepository.addResin`; un stock ≤ 0 toma el precio nuevo). Solo la resina lleva el stock al día (`PrintMaterial.tracksStock`).
- **Filamento = lista de colores con su precio** (€/kg), agrupados por nombre/marca, con una bobina del color deducido del texto; no se controlan gramos (el usuario sabe lo que le queda), así que no hay estados de stock ni avisos de falta (`StockCheck` solo mira la resina). Al completar un pedido se sigue restando del campo interno de stock, sin mostrarse.
- **Añadir varios**: marca + precio por defecto + lista de colores (uno por línea; `Color: precio` para precio propio; sin vacíos ni repetidos) crea todos los filamentos de golpe (`BulkFilaments`).
- Buscador por nombre o color (solo filamento). Alta/edición con validación (nombre obligatorio, €/kg ≥ 0; en resina también los gramos).
- **Borrar**: si alguna placa usa el material **no se borra** y se avisa de cuántas; si no, pide confirmación.
- Las placas y mermas **pueden no tener material** (v8): así quedan las importadas del Excel, que conservan su coste congelado.

### 4.5 Piezas extra (`features/extras`)

- Franja resumen (nº de piezas, valor del stock = Σ precio × stock con stock > 0, agotadas) y tarjetas con precio unitario, stock grande y etiqueta (Agotado, Stock negativo, Pocas unidades 1–5).
- **Alta por paquete**: unidades y precio total; precio unitario = total / unidades (o el total si no hay unidades). **Editar** cambia solo el nombre y el precio unitario: el stock no se toca (se usa «Sumar unidades»).
- **Sumar unidades**: unidades y precio pagado; el precio unitario pasa a la **media ponderada** `(precio × stock + total) / (stock + unidades)` (un stock negativo cuenta como 0). Muestra el precio antes → después. La operación lee stock y precio actuales de la base de datos dentro de una transacción.
- Borrar con confirmación.

### 4.6 Clientes (`features/clients`)

- Buscador (nombre, teléfono, email) y rejilla adaptable de tarjetas con avatar de iniciales, teléfono y email (con botón de copiar), «N pedidos · €X facturado» y, si debe dinero, «Debe €Y».
- Alta/edición con todos los campos opcionales: si todo está vacío no se guarda; sin nombre se usa el teléfono o el email. **Eliminar** un cliente (con confirmación) conserva sus pedidos, que quedan sin cliente.

### 4.7 Administración (`features/settings`)

Nueve ajustes agrupados en cuatro tarjetas, cada uno con ayuda, valor por defecto y «restaurar»:

| Grupo | Ajuste | Clave | Por defecto |
|---|---|---|---|
| Precio | Margen sobre el coste (%) | `margen_beneficio` | 150 |
| Precio | Precio mínimo (€) | `precio_minimo` | 5 |
| Producción | Precio de la electricidad (€/kWh) | `precio_kwh` | 0,15 |
| Producción | Coste de la máquina: desgaste (€/h) | `coste_maquina_hora` | 0,10 |
| Producción | Coste por placa (€) | `coste_placa` | 1 |
| Pintura | Pintura simple (€ que se suman) | `precio_pintura_simple` | 20 |
| Pintura | Pintura normal (€) | `precio_pintura_normal` | 60 |
| Pintura | Pintura detallada (€) | `precio_pintura_detallada` | 100 |
| Objetivos | Objetivo de beneficio (€) | `objetivo_beneficio` | 5000 |

- Validación estricta en el campo (vacío, no numérico, negativo o margen > 1000 no se aceptan ni se sustituyen por el defecto); «Guardar» solo si hay cambios válidos; indicador «Cambios sin guardar»; «Restaurar valores por defecto» con confirmación; tarjeta **«Ejemplo en vivo»** que calcula un pedido de muestra (100 g a 20 €/kg, 8 h) con los valores escritos.
- Afectan a los cálculos desde ese momento; el precio guardado en un pedido no cambia. Las claves de modelos anteriores (`margen_seguridad`, `coste_kwh`, `tarifa_placa_*`, `coste_pintura_*`…) se conservan en la base de datos pero no se usan.

## 5. Movimientos de stock

| Acción | Material (`stock_g`) | Piezas (`stock`) |
|---|---|---|
| Crear pedido | — | − cantidades |
| Editar pedido | — | + anteriores, − nuevas (si se envían piezas) |
| **Completar** | − gramos de cada material (suma de placas) **menos lo ya registrado como merma de ese material en el pedido** (mínimo 0). Una sola vez | — |
| Registrar merma | − gramos perdidos | — |
| Borrar pedido | **no se repone** (ya se gastó) | + cantidades |
| Sumar unidades a pieza | — | + unidades (atómico) |

Todo se hace en una transacción. Completar un pedido ya cerrado no hace nada; completar uno cancelado se rechaza.

## 6. Base de datos

- Archivo `nesher_erp_v6.db` (el «v6» es histórico); versión del esquema (`PRAGMA user_version`) = **8**. Esquema único en `lib/core/database/db_schema.dart`: `onCreate` crea tablas y ajustes; `onUpgrade` asegura todas las tablas y aplica migraciones `if (oldVersion < N)`; `onOpen` es una red de seguridad.
- Migraciones: v2 clientes, placas y piezas; v3 intentos, horas de pintura, colores y coste fijo en pedidos; v4 detalle de pintura (ya no se usa; la columna `paint_detail` y `paint_colors` se conservan sin usar); **v6 pintura por detalle** (columna `paint_level`; las horas y la tarifa de pintura dejan de usarse); **v7 congela el coste** de los pedidos completados/enviados en `cost_override` (sin columnas nuevas; K1); **v8 retira los materiales «Histórico (Excel)»** de la importación (placas y mermas pasan a no tener material, material_id opcional; antes congela `cost_override` de los pedidos que los usaban); **v5 modelo de precios simple**: añade los ajustes nuevos y devuelve el margen a su valor por defecto (ahora es un % sobre el coste, no un multiplicador distinto).
- **Copia de seguridad**: antes de migrar a una versión nueva, `AppDatabase` copia el archivo junto al original (`<archivo>.bak-v<versión>-<fecha>`).
- `PRAGMA foreign_keys` no está activado; el borrado de pedidos elimina explícitamente sus placas, mermas, piezas y consumos.

## 7. Pruebas

Todas pasan, sin omitidas (`bash .claude/skills/verify/verify.sh`):
- Reglas puras: calculadora (pedidos reales del Excel), estados, validación, panel, costes, clientes, piezas.
- Repositorios con SQLite en memoria: `stock_invariants_test.dart` (cada test protege un fallo real ya corregido), `repositories_test.dart` (incluye migraciones v1→v8), copia de seguridad con archivos reales.
- Pantallas con toques simulados: `test/app/order_flow_test.dart` (crear, completar, enviar, validación, duplicar, editar conservando piezas, eliminar, y **ningún desborde** en escritorio y móvil) y una prueba por pantalla.

## 8. Problemas conocidos

Resueltos en nov-2026 (con test): recargo de placas acumulativo; horas de pintura sin guardar; editar pedidos perdía las piezas; borrar dejaba placas y mermas huérfanas; completar dos veces, o tras una merma, descontaba material de más; Enviado sin completar; guardado sin validar ni avisar de errores; stock de piezas pisado por datos de pantalla viejos; precio de piezas re-registrado al editar; neto del panel sin coste de material; estados en inglés; borrar material sin confirmar ni comprobar uso; ajustes con valores inválidos sustituidos en silencio.

Resueltos después: **K1** (coste congelado al completar, esquema v7), **K2** (editar una pieza ya no pisa su stock), **K4** (una pieza eliminada del catálogo se conserva en los pedidos que ya la tenían) y **K6** (se pueden eliminar clientes; sus pedidos se conservan).

Vigentes:

| # | Qué pasa | Impacto |
|---|---|---|
| K3 | El stock de material puede quedar negativo al completar o registrar mermas. Al completar, el diálogo de confirmación avisa de qué material no alcanza (`StockCheck`), pero se permite seguir. | Inventario negativo si se ignora el aviso. |
| K5 | No hay forma de reabrir un pedido completado por error (decisión deliberada: el material ya se descontó y los pedidos importados nunca lo descontaron, así que no se puede saber qué devolver). | Hay que borrarlo y recrearlo. |

## 9. Importación del histórico del Excel

`tool/import_finanza.py <Finanza.ods> <base.db> [--apply]` (una sola vez, con la app cerrada). Sin `--apply` simula y muestra el cuadre; con `--apply` hace antes una copia `.bak-import-<fecha>`.
- Un pedido por fila con nombre: precio cobrado (I), coste de la hoja (Z) como `cost_override` (en curso y completados), estados 0/1/2 → Borrador/En curso/Completado (cobrado = precio en los completados; el adelanto en los demás). No toca el stock.
- Una placa «Importado» por pedido (gramos y horas totales de la hoja) con un material «Histórico (Excel)» por cada €/kg distinto, con stock 0. Las 11 piezas de la tabla de materiales de la hoja, con stock 0.
- Fechas: la hoja solo tenía fecha en 32 de 141 filas; el resto usa la última fecha conocida de las filas anteriores y lo dice en las notas.
- Cuadre: aborta si los completados no suman la celda G3 (5485 €). Importación real (24-nov-2026): 141 pedidos (40 borrador, 5 en curso, 96 completados), 5485 € facturados, coste de la hoja 2287,26 €.
