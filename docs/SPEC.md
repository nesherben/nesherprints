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
| Pedido (`Order`) | `orders` | cliente (opcional), proyecto, precio final, cobrado, fecha `YYYY-MM-DD`, estado, pintado, notas, **intentos**, **horas de pintura**, **detalle de pintura** (pocos/normal/muchos), **coste fijo** (solo importados) |
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
- **Producción**: intentos (decimal, 1 = a la primera) y servicio de pintura (horas + detalle pocos/normal/muchos).
- **Resumen**: nº de placas, tiempo y gramos; desglose (material, luz, recargo por placas, pintura, piezas) y nota de intentos; **coste real**; **precio recomendado** con «Aplicar»; precio final con valoración en texto (verde «Beneficio X (+Y % sobre el coste)», ámbar «Por debajo del recomendado», rojo «Pierdes X»); cobrado con atajos `0 € / 50 % / Todo` y «Falta por cobrar».
- **Validación** (`OrderRules.validateForm`): nombre obligatorio, al menos una placa, cada placa con material y gramos > 0, tiempo ≥ 0, precio ≥ 0 (0 vale para regalos), cobrado ≥ 0, intentos > 0, horas de pintura ≥ 0. Los errores se muestran en el pie y se actualizan al corregir.
- **Guardado**: asíncrono; el diálogo no se cierra hasta que se guarda. Si falla, se queda abierto con el error y sin perder lo escrito. `Ctrl+S` guarda.
- Si el pedido está cerrado: banner informativo, todo en solo lectura y sin botón de guardar.
- **Duplicar**: pedido nuevo en Borrador, con las placas (sin ids) y piezas del original, nombre «… (copia)», fecha de hoy y cobrado 0.
- Al **crear**: se guardan pedido, placas y piezas; se **resta el stock de las piezas** (no el del material). Al **editar**: las placas y piezas se reemplazan por las del formulario (lista vacía = borrar); las piezas anteriores se devuelven al stock y se aplican las nuevas, conservando el precio registrado de las que ya estaban.

**Merma** (`WasteDialog`): se elige la placa y el % que llegó a imprimirse (de 5 en 5); gramos = gramos de la placa × %. Se guarda y **se resta del material**. Motivo opcional («Fallo al N % en <placa>» por defecto). No se puede registrar una merma de 0 g.

### 4.2 Calculadora de precios (`PricingCalculator`)

Transcrita del Excel `Finanza.ods` (detalle y casos reales en [`EXCEL_FORMULAS.md`](EXCEL_FORMULAS.md)); los tests usan pedidos reales de la hoja.

```
mat    = Σ gramos/1000 × €/kg de su material
horas  = Σ minutos / 60            n = nº de placas      hPlaca = horas / n
tarifa = media de (resina ? tarifaResina : tarifaFilamento) de las placas
recargo = max(0, (n−1) × tarifa × (1 + 0,1·(n−1)))        # la 1.ª placa no paga
seg    = 1 + margenSeguridad/100
pintura = pintado ? (horasPintura × €/h + materialSegúnDetalle) × seg : 0

COSTE = max(0, (mat × intentos + horas × kWh × intentos + recargo) × seg + pintura) + piezas

luz     = n × (hPlaca ≤ 12 ? hPlaca : 12 + 15·ln(hPlaca/12)) × kWh      # se amortigua
largo   = hPlaca ≤ 8 ? 1 : 1 + 0,085·ln(hPlaca/8)                       # impresión larga
RECOMENDADO = (mat×2 + luz + recargo) × largo × (2 + margenBeneficio/100)
              + pintura + piezas × (1 + margenBeneficio/100)
```

- Los intentos solo afectan al coste, no al recomendado. Las piezas suman al coste a su precio y al precio con el margen (decisión provisional).
- Con varios materiales, el recargo usa la media de tarifas de las placas.
- Diferencia con el Excel: la hoja multiplica por `1 + (S+100)/100` (con S = 0,15 vale 2,0015); la app usa `2 + margen/100` = 2,15.
- **Semáforo** (frente al coste y al recomendado): neutro si precio o coste ≤ 0; bueno si precio ≥ recomendado; bajo si coste < precio < recomendado; pérdida si precio ≤ coste.

### 4.3 Panel (`features/dashboard`)

- **Indicadores**: Facturado (suma de pedidos completados o enviados), **Beneficio real** (facturado − coste real; con su margen %), **Pendiente de cobro** (deuda de pedidos que no son borrador ni cancelados) y **Objetivo** (beneficio «teórico» / objetivo configurable, con barra de progreso).
- **Beneficio teórico** = real + coste de pintura (como la columna `AB` del Excel).
- **Coste real** de cada pedido cerrado: su coste fijo si lo tiene (`costOverride`, pedidos importados); si no, se **recalcula** con sus placas, piezas (a su precio registrado), intentos y pintura, con los ajustes y precios de material **actuales**.
- Gráfica de barras de facturado y beneficio por mes (con scroll si hay muchos meses y tooltips), anillo de pedidos por estado, **detalle mensual** (pedidos, facturado, beneficio, margen; el mes más reciente primero) y lista de **pendientes de cobro** con su antigüedad.
- Las **mermas** no se restan del beneficio (ya van en los intentos); se muestran como nota informativa con su coste.

### 4.4 Inventario (`features/inventory`)

- Franja resumen (nº de materiales, kg totales, nº con stock bajo) y buscador por nombre, color o tipo.
- Tarjetas con icono por tipo, color, €/kg, barra de stock (verde/ámbar/rojo; **bajo** si < 200 g) y acciones. Vacío: estado vacío con botón de alta.
- Alta/edición con validación (nombre obligatorio, €/kg y stock obligatorios y ≥ 0).
- **Borrar**: si alguna placa usa el material **no se borra** y se avisa de cuántas; si no, pide confirmación.

### 4.5 Piezas extra (`features/extras`)

- Franja resumen (nº de piezas, valor del stock = Σ precio × stock con stock > 0, agotadas) y tarjetas con precio unitario, stock grande y etiqueta (Agotado, Stock negativo, Pocas unidades 1–5).
- **Alta/edición por paquete**: unidades y precio total; precio unitario = total / unidades (o el total si no hay unidades). Al editar, las unidades **sustituyen** al stock.
- **Sumar unidades**: unidades y precio pagado; el precio unitario pasa a la **media ponderada** `(precio × stock + total) / (stock + unidades)` (un stock negativo cuenta como 0). Muestra el precio antes → después. La operación lee stock y precio actuales de la base de datos dentro de una transacción.
- Borrar con confirmación.

### 4.6 Clientes (`features/clients`)

- Buscador (nombre, teléfono, email) y rejilla adaptable de tarjetas con avatar de iniciales, teléfono y email (con botón de copiar), «N pedidos · €X facturado» y, si debe dinero, «Debe €Y».
- Alta/edición con todos los campos opcionales: si todo está vacío no se guarda; sin nombre se usa el teléfono o el email. No se pueden borrar clientes.

### 4.7 Administración (`features/settings`)

Ocho ajustes agrupados en tarjetas (Precio, Energía y placas, Pintura, Objetivos), cada uno con ayuda, valor por defecto y «restaurar»:

| Ajuste | Clave | Por defecto |
|---|---|---|
| Margen de beneficio (%): el recomendado se multiplica por 2 + margen | `margen_beneficio` | 15 |
| Margen de seguridad del coste (%) | `margen_seguridad` | 15 |
| Coste de luz (€/h de impresión) | `coste_kwh` | 0,0375 |
| Recargo por placa extra, filamento / resina (€) | `tarifa_placa_filamento` / `tarifa_placa_resina` | 0,5 / 1,5 |
| Coste de pintado (€/h) | `coste_hora_pintado` | 8 |
| Material de pintura: pocos / normal / muchos (€) | `coste_pintura_pocos` / `_normal` / `_muchos` | 3/90 · 9/90 · 13/90 |
| Objetivo de beneficio (€) | `objetivo_beneficio` | 5000 |

- Validación estricta en el campo (vacío, no numérico, negativo o margen > 1000 no se aceptan ni se sustituyen por el defecto); «Guardar» solo si hay cambios válidos; indicador «Cambios sin guardar»; «Restaurar valores por defecto» con confirmación; tarjeta **«Ejemplo en vivo»** que calcula un pedido de muestra con los valores escritos.
- Afectan a los cálculos desde ese momento; el precio guardado en un pedido no cambia. `coste_placa_extra` y `coste_unidad_color` están obsoletas (se conservan).

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

- Archivo `nesher_erp_v6.db` (el «v6» es histórico); versión del esquema (`PRAGMA user_version`) = **4**. Esquema único en `lib/core/database/db_schema.dart`: `onCreate` crea tablas y ajustes; `onUpgrade` asegura todas las tablas y aplica migraciones `if (oldVersion < N)`; `onOpen` es una red de seguridad.
- v2: clientes, placas, piezas. v3: intentos, horas de pintura, colores y coste fijo en pedidos + ajustes del Excel (los ajustes antiguos 45 % y 15 €/h pasan a 15 % y 8 €/h solo si no se habían editado). v4: detalle de pintura (los colores guardados se convierten: ≤ 4 pocos, 5–10 normal, > 10 muchos; la columna antigua se conserva).
- **Copia de seguridad**: antes de migrar a una versión nueva, `AppDatabase` copia el archivo junto al original (`<archivo>.bak-v<versión>-<fecha>`).
- `PRAGMA foreign_keys` no está activado; el borrado de pedidos elimina explícitamente sus placas, mermas, piezas y consumos.

## 7. Pruebas

139 pruebas, sin omitidas (`bash .claude/skills/verify/verify.sh`):
- Reglas puras: calculadora (pedidos reales del Excel), estados, validación, panel, costes, clientes, piezas.
- Repositorios con SQLite en memoria: `stock_invariants_test.dart` (cada test protege un fallo real ya corregido), `repositories_test.dart` (incluye migraciones v1→v4), copia de seguridad con archivos reales.
- Pantallas con toques simulados: `test/app/order_flow_test.dart` (crear, completar, enviar, validación, duplicar, editar conservando piezas, eliminar, y **ningún desborde** en escritorio y móvil) y una prueba por pantalla.

## 8. Problemas conocidos

Resueltos en nov-2026 (con test): recargo de placas acumulativo; horas de pintura sin guardar; editar pedidos perdía las piezas; borrar dejaba placas y mermas huérfanas; completar dos veces, o tras una merma, descontaba material de más; Enviado sin completar; guardado sin validar ni avisar de errores; stock de piezas pisado por datos de pantalla viejos; precio de piezas re-registrado al editar; neto del panel sin coste de material; estados en inglés; borrar material sin confirmar ni comprobar uso; ajustes con valores inválidos sustituidos en silencio.

Vigentes:

| # | Qué pasa | Impacto |
|---|---|---|
| K1 | El panel **recalcula** el coste de los pedidos cerrados con los precios de material y ajustes actuales: si cambias un €/kg o un margen, cambia el beneficio histórico. | Cifras históricas inestables. Mejora prevista: congelar el coste al completar. |
| K2 | Los pedidos importados (`costOverride`) no conocen su parte de pintura: su beneficio «teórico» es igual al real. | Objetivo algo infravalorado. |
| K3 | Editar una pieza sobrescribe su stock con las «unidades por paquete». | Se pierde el stock real si se usa mal. |
| K4 | El stock de material puede quedar negativo al completar o registrar mermas (solo hay aviso en el formulario). | Inventario incoherente sin aviso. |
| K5 | Si una pieza se elimina del catálogo, desaparece de los pedidos que la tenían al editarlos. | Pérdida silenciosa en casos raros. |
| K6 | No hay forma de reabrir un pedido completado por error (decisión deliberada: el material ya se descontó). | Hay que borrarlo y recrearlo. |
| K7 | Los clientes no se pueden borrar; un cliente con pedidos no tiene restricción. | — |
