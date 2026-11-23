# CLAUDE.md — NesherPrints ERP

App Flutter de escritorio/Android para gestionar un negocio de impresión 3D: pedidos con calculadora de precio, inventario de material, piezas extra, clientes y panel de facturación. SQLite local, un usuario, UI en español.

**Especificación funcional (reglas, fórmulas, stock, problemas conocidos): [`docs/SPEC.md`](docs/SPEC.md).** Léela antes de tocar lógica de negocio.

## Comandos

```bash
bash .claude/skills/verify/verify.sh            # analyze + tests (usar siempre este, no flutter analyze/test a pelo)
bash .claude/skills/verify/verify.sh test test/features/repositories_test.dart
bash .claude/skills/code-map/code_map.sh lib/features/orders   # esquema de clases/métodos
bash .claude/skills/code-map/usages.sh OrderRepository          # dónde se usa algo
flutter run -d windows
dart format lib test
```

## Mapa

```
lib/
├── main.dart                     init SQLite FFI en escritorio + runApp
├── app/
│   ├── app.dart                  MaterialApp (tema, título)
│   ├── main_layout.dart          NavigationRail + pantalla activa; dueño de la lista de pedidos
│   └── service_locator.dart      repositorios únicos sobre AppDatabase.instance
├── core/
│   ├── constants/app_constants.dart   FinanceDefaults, SettingKeys, InventoryRules, WasteRules
│   ├── database/
│   │   ├── app_database.dart     abre la BD (archivo real o inMemory() para tests)
│   │   └── db_schema.dart        ÚNICO sitio del esquema: tablas/columnas, onCreate/onUpgrade/onOpen
│   ├── strings/app_strings.dart  TODOS los textos de UI, por secciones
│   ├── theme/                    AppColors, AppTheme, AppTextStyles, AppButtonStyles
│   ├── utils/                    parseDecimal/parseInt/asDouble, formatEuro/todayIsoDate, input formatters
│   └── widgets/                  PageHeader, showConfirmDialog, LoadingDialog
└── features/<feature>/
    ├── domain/                   modelos (fromMap/toMap) y lógica pura testeable
    ├── data/                     <feature>_repository.dart (SQL)
    └── presentation/             <feature>_view.dart + widgets/
```

| Feature | Domain | Data | Presentation |
|---|---|---|---|
| `orders` | `Order`, `OrderSummary`, `OrderStatus`/`PlateStatus`, `OrderPlate`, `OrderExtraLine`, `WasteRecord`, `PricingCalculator`/`PriceHealth` | `OrderRepository` (crear/editar/completar/borrar/merma, todo con stock en transacción) | `OrdersView`, `OrderDataTable`, `StatusBadge`, `WasteDialog`, `order_form/` (diálogo + secciones placas/extras/finanzas) |
| `dashboard` | `FinanceSummary.compute` | — (usa repos de orders/inventory) | `DashboardView`, `KpiCard`, `MonthlyRevenueChart`, `StatusPieChart` |
| `inventory` | `PrintMaterial`, `MaterialKind` | `MaterialRepository` | `InventoryView`, `MaterialDialog`, `MaterialKindChip` |
| `extras` | `Extra`, `ExtraPricing` | `ExtrasRepository` (incl. `addStock`) | `ExtrasView`, `ExtraCard`, `ExtraDialog`, `AddStockDialog` |
| `clients` | `Client` (`fromForm` aplica reglas) | `ClientRepository` | `ClientsView`, `ClientCard`, `ClientFormDialog` |
| `settings` | `PricingSettings` | `SettingsRepository` | `SettingsView` (pantalla "Administración") |

Flujo de datos: Vista → `ServiceLocator.<repo>` → `AppDatabase` → SQLite. Los pedidos los carga `MainLayout` y los pasa a `DashboardView` y `OrdersView`; las escrituras de pedidos (`_saveOrder`, `_completeOrder`…) viven en `MainLayout`.

## Convenciones

- **Comportamiento**: el refactor de nov-2026 no cambió reglas. Antes de "arreglar" algo, mira si está en *Problemas conocidos* de `docs/SPEC.md` y confírmalo con el usuario.
- **Base de datos**: datos reales del usuario. Nunca renombres tablas/columnas ni valores persistidos (`OrderStatus.dbValue`, `SettingKeys`, `MaterialKind.dbValue`) sin migración. Cambios de esquema: subir `DbSchema.version`, añadir `if (oldVersion < N)` en `onUpgrade`, actualizar `onCreate` y añadir test de migración en `repositories_test.dart`.
- **Lógica** en `domain/` como funciones/clases puras con test; los repositorios solo SQL + transacciones; las vistas solo UI y llamadas a repositorios.
- **Modelos** tipados; nada de `Map<String, dynamic>` fuera de `fromMap`/`toMap`. Nombres de columnas desde las clases `*Table` de `db_schema.dart`.
- **Textos** solo en `AppStrings` (español). **Colores** solo de `AppColors`; estilos repetidos en `AppTextStyles`/`AppButtonStyles`.
- **Imports** absolutos `package:nesherprints/...`, ordenados: `dart:`, paquetes, proyecto.
- **Async en State**: `if (!mounted) return;` tras cada `await` antes de `setState`/`context`.
- Identificadores en inglés, comentarios y UI en español.
- Tests: lógica pura en `test/features/<feature>/`, repositorios con `AppDatabase.inMemory()` (nunca la BD real).

## Skills y agentes (`.claude/`)

- Skills: `verify`, `code-map`, `device` (Android por adb), `bump-version` (versión + release), `/feature` (equipo analista + diseñador + revisor), `/user-test`.
- Agentes: `feature-analyst`, `product-designer`, `code-reviewer`, `user-tester`.
