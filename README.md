# NesherPrints ERP

Aplicación Flutter para gestionar un pequeño negocio de **impresión 3D**: pedidos, clientes, inventario de material, extras y finanzas, todo en local y sin cuentas ni servidores.

## Funcionalidades

| Pantalla | Qué hace |
| --- | --- |
| **Panel** | KPIs (ingresos brutos, beneficio neto, pendiente de cobro) y gráficas con `fl_chart`. |
| **Pedidos** | Tabla con estados (Draft, Reserved, In Progress, Completed, Shipped, Canceled), pagos, filtros y registro de merma. |
| **Formulario de pedido** | Cliente, varias placas (gramos, minutos, material), extras, pintado y cálculo de coste/precio sugerido con margen. |
| **Inventario** | Materiales (filamento y resina) con coste por kg, stock en gramos, aviso de stock bajo y alta de stock. |
| **Piezas (Extras)** | Artículos adicionales con precio medio ponderado, stock y unidad. |
| **Clientes** | Alta y edición con teléfono, email y notas. |
| **Administración** | Margen de beneficio, coste de pintado y coste por placa extra. |

Al completar un pedido se descuenta el stock de material; las pérdidas se registran como merma.

## Stack

- Flutter (Dart ^3.11), Material 3, tema oscuro
- SQLite: `sqflite` (Android/iOS) y `sqflite_common_ffi` (Windows/Linux/macOS)
- `fl_chart` para las gráficas

## Estructura

```
lib/
├── app/             # MaterialApp, navegación lateral y service locator
├── core/            # base de datos (esquema único), constantes, textos, tema, utilidades, widgets comunes
└── features/        # orders · dashboard · inventory · extras · clients · settings
    └── <feature>/
        ├── domain/        # modelos y lógica pura (precios, finanzas…)
        ├── data/          # repositorio SQLite
        └── presentation/  # pantalla y widgets
```

Los datos se guardan en un archivo SQLite local que se crea en el primer arranque.

- **Especificación funcional** (reglas, fórmulas, movimientos de stock): [`docs/SPEC.md`](docs/SPEC.md)
- **Mapa del código y convenciones**: [`CLAUDE.md`](CLAUDE.md)

## Ejecutar

Requisitos: Flutter estable con Dart 3.11 o superior. En Windows de escritorio, Visual Studio con la carga de trabajo "Desarrollo para el escritorio con C++".

```bash
flutter pub get
flutter run -d windows        # o -d <dispositivo Android>
```

```bash
flutter analyze               # análisis estático
flutter test                  # tests
flutter build apk --release   # APK de release
```

## Licencia

GPL v2. Consulta el archivo [LICENSE](LICENSE).
