# Revisión de la app — 23-nov-2026

Resumen de la revisión hecha con tres agentes (analista técnico, diseñador UI/UX y experto en negocio) sobre el estado tras el refactor, la calculadora del Excel (v3) y el detalle de pintura (v4). Objetivo: dejar el Excel para el **1/1/2027**.

Estado: 50 tests y análisis estático en verde; la app compila y arranca en Windows. Los agentes revisaron el código; **nadie ha recorrido la interfaz a mano todavía**.

## 1. Hallazgo al arrancar

La base de datos de desarrollo (`.dart_tool/sqflite_common_ffi/databases/`) tiene `margen_beneficio = 220`, el valor de la fórmula antigua. La migración solo cambia el valor por defecto antiguo (45), así que ese 220 se respetó. Con la fórmula nueva el multiplicador del precio es `2 + margen/100` = **×4,2** en vez de ×2,15. **Hay que poner 15 en Administración.** La app no hizo copia de la base de datos antes de migrarla a la v4.

## 2. Bugs que pueden corromper datos (antes de importar el Excel)

| # | Problema (verificado en el código) | Arreglo | Esfuerzo |
|---|---|---|---|
| 1 | **Completar dos veces descuenta el material dos veces.** El cambio rápido de estado permite salir de `Completed` y volver a completar. | Comprobar el estado dentro de la transacción; no permitir salir de Completed. | S |
| 2 | **Borrar un pedido** deja placas y mermas huérfanas; las mermas huérfanas siguen restando en el neto del panel. | Borrar placas y mermas en la misma transacción; decidir si se repone el stock. | S |
| 3 | **El guardado de pedido no tiene `await` ni `try/catch`**: si falla, el diálogo se cierra y se pierde lo escrito sin avisar. Tampoco hay manejo de errores global. | `onSave` asíncrono, avisar sin cerrar, `runZonedGuarded`. | M |
| 4 | **Merma + Completar** resta dos veces el material de esa placa; la merma de 0 % y el doble clic también guardan. | Al completar, restar gramos menos merma ya registrada; deshabilitar el botón mientras guarda. | M |
| 5 | **`addStock` con datos viejos** sobrescribe el stock de piezas (la pantalla no se recarga tras crear un pedido). | `UPDATE stock = stock + ?` en transacción y recargar. | S |
| 6 | **Editar un pedido no carga sus piezas** y las re-graba al precio actual; no se pueden quitar todas las placas o piezas. | Cargar piezas, pasar siempre las listas. | M |
| 7 | **`Shipped` no descuenta material** ni marca cobrado; para completarlo hay que volver atrás (ver 1). | Decisión de producto. | S |
| 8 | **Sin copia de seguridad antes de migrar**; una versión antigua de la app no arranca con una BD nueva. | Copiar el `.db` antes de subir de versión. | S |
| 9 | **Sin validación**: nombre vacío, precio ≤ 0, gramos negativos, intentos 0 (hace desaparecer material y luz del coste). | Validador puro con tests + guarda en el repositorio. | M |
| 10 | **El neto del panel no descuenta el material** de los pedidos nuevos (P1): lee la tabla heredada `order_items`. | Usar `OrderSummary.materialCost` o el coste calculado. | M |

Menores: ponderar el precio de piezas con stock negativo da 0,93 € en vez de 0,8 €; un valor no numérico en Administración pisa el del usuario con el por defecto; `PlateStatus.success/failed` no se usa. Faltan tests de invariante de stock (crear → editar → completar → merma → borrar).

## 3. Negocio

- **Falta para dejar la hoja:** panel con objetivo, ratio mensual, beneficio real y teórico (G3 5.485 €, F3 3.176,51 €, E3 3.705,44 €, H3 67,56 %), y el importador.
- **Tiempo de máquina casi regalado**: espadón 80 € por 59 h = 1,36 €/h; armored 0,92 €/h; nun gothic 0,87 €/h. El coste no incluye tu trabajo (laminar, quitar soportes, lijar, empaquetar), el desgaste de la impresora, comisiones, envío ni impuestos, así que el 67,56 % de beneficio engaña.
- **El recomendado de la app como precio de venta:** en piezas grandes cobras entre 8 % y 14 % menos que el recomendado (×2,15); en piezas pequeñas cobras de 2 a 4 veces lo recomendado (3–11 €). Hace falta un **precio mínimo**.
- **Objetivo de 5.000 €:** a unos 370 €/mes se llega hacia marzo-abril de 2027, no el 1/1. El objetivo debe medirse en beneficio real o teórico (los separan 529 €).
- **Cobros pendientes:** 5 pedidos confirmados por 250,50 €; "fernanda baño" lleva abierto desde marzo-abril.
- **Migración:** 3 versiones de fórmula en el histórico (filas 6–135 sin luz); la mayoría de filas no tiene fecha; el stock inicial hay que contarlo a mano; los lotes (filas 62–69) se importan con el coste ya multiplicado.

**Decisiones tuyas pendientes:** ¿×2,15 definitivo? · ¿tiempo propio y desgaste de impresora (€/h)? · ¿precio mínimo por pedido? · ¿precios con IVA? · ¿objetivo en beneficio real o teórico? · ¿cómo se cuentan los regalos (filas 139 y 146)? · piezas con margen (Q6) y lotes con cantidad (Q7) · ¿fecha por defecto para los históricos sin fecha?

## 4. UI/UX

**Arreglar:** estados en español (hoy salen "In Progress", "Shipped"…; solo cambia `label`, no el valor guardado) · validación y errores en el formulario · semáforo del precio sin explicar (añadir texto e icono: "Pierdes 3,20 €") · diálogo de pedido demasiado largo (el recomendado queda al final) · tabla sin paginación ni cabecera fija, buscador solo por proyecto, acciones sin tooltip · Administración: 10 ajustes en lista plana sin ayudas · borrar material sin confirmar · contraste del rojo y textos de 9–11 px.

**Añadir (por valor):** resumen de precio fijo en el formulario con desglose · panel del mes con objetivo y pendiente · atajos de teclado (`Ctrl+N`, `Ctrl+F`, `Ctrl+S`) · duplicar pedido · detalle de pedido · agrupar por mes con filtros rápidos · aviso de stock en el formulario · presupuesto en PDF para el cliente · exportar CSV y copia de seguridad.

## 5. Plan hasta el 1/1/2027

| Semana | Trabajo |
|---|---|
| 1 | Bugs 1–9 de la sección 2 con sus tests, copia de seguridad antes de migrar, estados en español, margen a 15. |
| 2 | Panel completo (objetivo, ratio, real/teórico, neto honesto) y resumen de precio fijo en el formulario. |
| 3 | Importador del Excel (materiales, piezas y pedidos con `cost_override`) con informe de cuadre contra los totales de la hoja; contar el stock inicial. |
| 4–5 | Ensayo en paralelo durante diciembre: cada pedido nuevo en la hoja y en la app; comparar a fin de mes. Mejoras de tabla, ajustes agrupados y duplicar pedido. Corte el 1/1 solo si cuadran. |
| Después | Detalle de pedido, PDF, atajos, CSV, tiempo propio y desgaste de impresora. |

## 6. Documentación desactualizada (arreglar)

- `SPEC.md` §6 dice que `onCreate` inserta 3 ajustes (son 10); §8 menciona la migración v1→v2 (los tests cubren hasta v3→v4); faltan en los problemas conocidos: doble Completar, `addStock` con datos viejos, re-snapshot de precios al editar, intentos ≤ 0 y stock de material negativo sin aviso.
- `EXCEL_FORMULAS.md` §1 aún dice que las horas de pintura "no se guardan" y que 45 % y 15 €/h son los valores por defecto; §6 habla de 8 ajustes (son 10).
