import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/inventory_view.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Pantalla de Inventario sobre una base de datos en memoria. Los accesos a la
/// BD usan un hilo real, de ahí `runAsync` al esperar.
void main() {
  late AppDatabase db;
  late List<String> overflows;

  setUp(() {
    db = AppDatabase.inMemory();
    ServiceLocator.useDatabase(db);
    overflows = [];
  });

  tearDown(() => db.close());

  Future<void> settle(WidgetTester t, {int rounds = 6}) async {
    for (var i = 0; i < rounds; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await t.pump(const Duration(milliseconds: 80));
    }
  }

  /// Registra los desbordes en [overflows] en vez de romper la prueba.
  void captureOverflows() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed by')) {
        overflows.add(details.exceptionAsString());
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  Future<List<PrintMaterial>> stored(WidgetTester t) async =>
      (await t.runAsync(() => ServiceLocator.materials.getAll()))!;

  Future<void> seed(WidgetTester t, List<PrintMaterial> materials) async {
    await t.runAsync(() async {
      for (final m in materials) {
        await ServiceLocator.materials.save(m);
      }
    });
  }

  Future<void> openView(
    WidgetTester t, {
    Size size = const Size(1600, 1000),
  }) async {
    captureOverflows();
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    // Abre la BD fuera del reloj simulado.
    await t.runAsync(() => ServiceLocator.materials.getAll());
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: InventoryView()),
      ),
    );
    await settle(t);
  }

  Future<void> tapText(WidgetTester t, String text) async {
    final finder = find.text(text).first;
    await t.ensureVisible(finder);
    await t.tap(finder);
    await settle(t);
  }

  Future<void> enter(WidgetTester t, String label, String value) async {
    await t.enterText(find.widgetWithText(TextField, label), value);
    await t.pump();
  }

  const pla = PrintMaterial(
    kind: MaterialKind.filament,
    name: 'PLA Silk',
    color: 'Negro',
    costPerKg: 20,
    stockGrams: 1000,
  );
  const resin = PrintMaterial(
    kind: MaterialKind.resin,
    name: 'Resina Elegoo',
    color: 'Gris',
    costPerKg: 35,
    stockGrams: 100,
  );

  testWidgets('muestra los materiales, el resumen y el stock bajo', (t) async {
    await seed(t, [pla, resin]);
    await openView(t);

    expect(find.text('PLA Silk'), findsOneWidget);
    expect(find.text('Resina Elegoo'), findsOneWidget);
    expect(find.text('Negro · €20.00/kg'), findsOneWidget);
    expect(find.text('1000 g'), findsOneWidget);
    expect(find.text('Stock bajo'), findsOneWidget, reason: 'solo la resina');
    expect(find.text('1.10 kg'), findsOneWidget, reason: 'stock total');
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets('sin materiales muestra el estado vacío con acción', (t) async {
    await openView(t);

    expect(find.text('Aún no hay materiales'), findsOneWidget);
    await tapText(t, 'Añadir Material');
    expect(find.text('Nombre/Marca'), findsOneWidget);
  });

  testWidgets('el buscador filtra por nombre, color y tipo', (t) async {
    await seed(t, [pla, resin]);
    await openView(t);

    await t.enterText(find.byType(TextField), 'gris');
    await settle(t, rounds: 2);
    expect(find.text('Resina Elegoo'), findsOneWidget);
    expect(find.text('PLA Silk'), findsNothing);

    await t.enterText(find.byType(TextField), 'filamento');
    await settle(t, rounds: 2);
    expect(find.text('PLA Silk'), findsOneWidget);
    expect(find.text('Resina Elegoo'), findsNothing);

    await t.enterText(find.byType(TextField), 'zzz');
    await settle(t, rounds: 2);
    expect(find.text('Sin resultados'), findsOneWidget);

    await t.tap(find.byTooltip('Borrar búsqueda'));
    await settle(t, rounds: 2);
    expect(find.text('PLA Silk'), findsOneWidget);
    expect(find.text('Resina Elegoo'), findsOneWidget);
  });

  testWidgets('alta: valida los campos y guarda el material', (t) async {
    await openView(t);
    await tapText(t, 'Añadir Material');

    await tapText(t, 'Guardar');
    expect(find.text('Indica el nombre o la marca'), findsOneWidget);
    expect(find.text('Indica un coste válido (0 o más)'), findsOneWidget);
    expect(find.text('Indica un stock válido (0 o más)'), findsOneWidget);
    expect(await stored(t), isEmpty);

    await tapText(t, 'Resina');
    await enter(t, 'Nombre/Marca', 'Anycubic');
    await enter(t, 'Color', 'Verde');
    await enter(t, 'Coste por Kg (€)', '30,5');
    await enter(t, 'Stock (gramos/ml)', '500');
    await tapText(t, 'Guardar');

    final saved = (await stored(t)).single;
    expect(saved.kind, MaterialKind.resin);
    expect(saved.name, 'Anycubic');
    expect(saved.color, 'Verde');
    expect(saved.costPerKg, 30.5);
    expect(saved.stockGrams, 500);
    expect(
      find.text('Anycubic'),
      findsOneWidget,
      reason: 'aparece en la lista',
    );
  });

  testWidgets('edición: cambia el nombre y conserva el id', (t) async {
    await seed(t, [pla]);
    await openView(t);
    final id = (await stored(t)).single.id;

    await t.tap(find.byTooltip('Editar'));
    await settle(t);
    await enter(t, 'Nombre/Marca', 'PLA Mate');
    await tapText(t, 'Guardar');

    final saved = (await stored(t)).single;
    expect(saved.id, id);
    expect(saved.name, 'PLA Mate');
    expect(find.text('PLA Mate'), findsOneWidget);
  });

  testWidgets('borrar pide confirmación y cancelar no borra', (t) async {
    await seed(t, [pla]);
    await openView(t);

    await t.tap(find.byTooltip('Eliminar'));
    await settle(t);
    expect(find.text('Confirmar eliminación'), findsOneWidget);
    await tapText(t, 'Cancelar');
    expect(await stored(t), hasLength(1));

    await t.tap(find.byTooltip('Eliminar'));
    await settle(t);
    await t.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
    await settle(t);
    expect(await stored(t), isEmpty);
    expect(find.text('Aún no hay materiales'), findsOneWidget);
  });

  testWidgets('un material usado en placas no se borra y se avisa', (t) async {
    await seed(t, [pla]);
    final id = (await stored(t)).single.id!;
    await t.runAsync(
      () => ServiceLocator.orders.create(
        const Order(
          name: 'Figura',
          price: 30,
          date: '2026-11-23',
          status: OrderStatus.inProgress,
        ),
        plates: [OrderPlate(name: 'A', grams: 50, minutes: 60, materialId: id)],
      ),
    );
    await openView(t);

    await t.tap(find.byTooltip('Eliminar'));
    await settle(t);

    expect(find.text('Confirmar eliminación'), findsNothing);
    expect(
      find.text(
        'No se puede eliminar "PLA Silk": lo usan 1 placas de pedidos.',
      ),
      findsOneWidget,
    );
    expect(await stored(t), hasLength(1));
  });

  for (final size in const [Size(1600, 1000), Size(420, 900)]) {
    testWidgets('sin desbordes a ${size.width.toInt()} px', (t) async {
      await seed(t, [
        pla,
        resin,
        const PrintMaterial(
          kind: MaterialKind.filament,
          name:
              'Un nombre de material especialmente largo para comprobar el '
              'recorte del texto en la tarjeta',
          color: 'Un color también muy largo, casi una descripción',
          costPerKg: 123456.78,
          stockGrams: 0,
        ),
      ]);
      await openView(t, size: size);
      expect(overflows, isEmpty, reason: 'lista');

      await t.tap(find.byTooltip('Editar').first);
      await settle(t);
      await enter(t, 'Nombre/Marca', '');
      await tapText(t, 'Guardar');
      expect(overflows, isEmpty, reason: 'diálogo con errores de validación');
    });
  }
}
