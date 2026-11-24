# CLAUDE.md — NesherPrints ERP

App Flutter de escritorio/Android para gestionar un negocio de impresión 3D: pedidos con calculadora de precio (modelo simple: coste × margen), inventario de material, piezas extra, clientes y panel de facturación. SQLite local, un usuario, UI en español.

**Especificación funcional (reglas, fórmulas, stock, problemas conocidos): [`docs/SPEC.md`](docs/SPEC.md).** Histórico de las fórmulas del Excel antiguo (para importar datos): [`docs/EXCEL_FORMULAS.md`](docs/EXCEL_FORMULAS.md). Léelas antes de tocar lógica de negocio.

## Comandos

```bash
bash .claude/skills/verify/verify.sh            # analyze + tests (usar siempre este, no flutter analyze/test a pelo)
bash .claude/skills/verify/verify.sh test test/features/orders/stock_invariants_test.dart
bash .claude/skills/code-map/code_map.sh lib/features/orders   # esquema de clases/métodos
bash .claude/skills/code-map/usages.sh OrderRepository          # dónde se usa algo
flutter run -d windows
dart format lib test
python tool/import_finanza.py <Finanza.ods> <base.db> [--apply]   # importación única del histórico (ya hecha)
```

No lances dos `flutter test` a la vez (se bloquean en `build/native_assets`).

## Mapa

```
lib/
├── main.dart                     init SQLite FFI en escritorio + runApp
├── app/
│   ├── app.dart                  MaterialApp (tema, título)
│   ├── main_layout.dart          navegación responsive + atajos + pantalla activa; dueño de la lista de pedidos
│   └── service_locator.dart      repositorios únicos sobre AppDatabase.instance (useDatabase para tests)
├── core/
│   ├── constants/app_constants.dart   FinanceDefaults, SettingKeys, InventoryRules, WasteRules
│   ├── database/
│   │   ├── app_database.dart     abre la BD (archivo real, file(), inMemory()); copia de seguridad antes de migrar
│   │   └── db_schema.dart        ÚNICO sitio del esquema: tablas/columnas, onCreate/onUpgrade/onOpen
│   ├── errors/app_exception.dart error con mensaje apto para el usuario
│   ├── strings/app_strings.dart  TODOS los textos de UI, por secciones
│   ├── theme/                    AppColors, AppTheme (tema global), AppSpacing/AppRadius, AppTextStyles, AppButtonStyles
│   ├── utils/                    números, formateo (€, fechas, meses, duración), input formatters, responsive
│   └── widgets/                  PageHeader, AppDialogFrame, SectionCard, StatusPill, EmptyState, AppFeedback, showConfirmDialog
└── features/<feature>/
    ├── domain/                   modelos (fromMap/toMap) y lógica pura testeable
    ├── data/                     <feature>_repository.dart (SQL)
    └── presentation/             <feature>_view.dart + widgets/
```

| Feature | Domain | Data | Presentation |
|---|---|---|---|
| `orders` | `Order`, `OrderSummary`, `OrderStatus` (reglas de estado) / `PlateStatus`, `OrderPlate`, `OrderExtraLine`, `WasteRecord`, `OrderRules` (validación), `PricingCalculator`/`PriceHealth`, `OrderCosting` | `OrderRepository` (crear/editar/completar/borrar/merma; todo el stock en transacción), `CostFreezer` (congela el coste al completar y en la migración v7) | `OrdersView`, `order_list.dart` (filas/tarjetas virtualizadas), `StatusBadge`, `WasteDialog`, `order_form/` (diálogo + placas, piezas, panel de resumen del precio) |
| `dashboard` | `FinanceSummary.compute` (beneficio, objetivo, mensual, pendientes) | — (usa repos de orders/inventory/settings) | `DashboardView`, `KpiCard`, `MonthlyRevenueChart`, `StatusPieChart`, `MonthlyTable`, `PendingList` |
| `inventory` | `PrintMaterial`, `MaterialKind` | `MaterialRepository` | `InventoryView`, `MaterialDialog`, tarjetas de material |
| `extras` | `Extra`, `ExtraPricing` | `ExtrasRepository` (incl. `addStock` atómico) | `ExtrasView`, `ExtraCard`, `ExtraDialog`, `AddStockDialog` |
| `clients` | `Client` (`fromForm` aplica reglas), `ClientStats` | `ClientRepository` | `ClientsView`, `ClientCard`, `ClientFormDialog` |
| `settings` | `PricingSettings` | `SettingsRepository` | `SettingsView` (pantalla "Administración") |

Flujo de datos: Vista → `ServiceLocator.<repo>` → `AppDatabase` → SQLite. Los pedidos los carga `MainLayout` y los pasa a `DashboardView` y `OrdersView`; las escrituras de pedidos (`_saveOrder`, `_completeOrder`…) viven en `MainLayout` y **lanzan** si fallan: quien las llama (formulario o listado) avisa al usuario.

## Convenciones

- **Reglas de negocio**: antes de cambiar una regla, mira `docs/SPEC.md` (§5 stock, §9 problemas conocidos) y las pruebas `stock_invariants_test.dart`: cada una protege un fallo real ya corregido.
- **Base de datos**: datos reales del usuario. Nunca renombres tablas/columnas ni valores persistidos (`OrderStatus.dbValue`, `SettingKeys`, `MaterialKind.dbValue`, `OrderStatus`…) sin migración. Cambios de esquema: subir `DbSchema.version`, añadir `if (oldVersion < N)` en `onUpgrade`, actualizar `onCreate` y añadir test de migración en `repositories_test.dart`. Antes de migrar, `AppDatabase` copia el archivo (`.bak-vN-fecha`).
- **Lógica** en `domain/` como funciones/clases puras con test; los repositorios solo SQL + transacciones (y las reglas de estado/stock); las vistas solo UI y llamadas a repositorios.
- **Modelos** tipados; nada de `Map<String, dynamic>` fuera de `fromMap`/`toMap`. Nombres de columnas desde las clases `*Table` de `db_schema.dart`.
- **Errores**: las operaciones lanzan `AppException` (mensaje para el usuario); la UI las muestra con `AppFeedback.failure`. Nada de `try/catch` vacíos ni de cerrar un diálogo antes de saber si se guardó.
- **UI**: textos solo en `AppStrings`; colores de `AppColors`; estilos de `AppTextStyles`/`AppSpacing`/`AppRadius`; diálogos con `AppDialogFrame` (nunca desbordan); campos sin bordes propios (los pone el tema). Todo `IconButton` lleva `tooltip`. Las pantallas se adaptan con `context.isCompact` / `isWide`.
- **Imports** absolutos `package:nesherprints/...`, ordenados: `dart:`, paquetes, proyecto.
- **Listas** (Pedidos, Inventario, Piezas, Clientes): barra con `ListToolbar` (buscador + chips de filtro en una línea), filas compactas con `RowActions` (una acción frecuente visible y el resto en el menú ⋮; **tocar la fila abre la edición**), rejilla con `AdaptiveSliverList` y cabeceras de bloque con `SectionHeader` (icono + título). El color va en los estados, no en las acciones. Botón principal en minúsculas: «Nuevo pedido/material/cliente», «Nueva pieza».
- **Async en State**: `if (!mounted) return;` tras cada `await` antes de `setState`/`context`.
- Identificadores en inglés, comentarios y UI en español.
- Tests: lógica pura en `test/features/<feature>/`, repositorios con `AppDatabase.inMemory()` (nunca la BD real), pantallas con `ServiceLocator.useDatabase` y captura de desbordes (ver `test/app/order_flow_test.dart`).

## Skills y agentes (`.claude/`)

- Skills: `verify`, `code-map`, `device` (Android por adb), `bump-version` (versión + release), `/feature` (equipo analista + diseñador + revisor), `/user-test`.
- Agentes: `feature-analyst`, `product-designer`, `code-reviewer`, `user-tester`.
