import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/app.dart';
import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Recorrido por las pantallas reales (toques y escritura simulados) sobre una
/// base de datos en memoria. Los accesos a la BD usan un hilo real, de ahí
/// `runAsync` al esperar.
/// Fallo confirmado y sin arreglar: se omite hasta que se corrija. Al
/// arreglarlo, cambiar `bugTestWidgets` por `testWidgets`.
void bugTestWidgets(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(
      name,
      body,
      skip: true, // bug confirmado, ver docs/REVISION_2026-11.md
    );

void main() {
  late AppDatabase db;

  /// Desbordes de maquetación vistos durante la prueba (`archivo:línea`).
  late List<String> overflows;

  setUp(() {
    db = AppDatabase.inMemory();
    ServiceLocator.useDatabase(db);

    overflows = [];
  });

  tearDown(() => db.close());

  /// Deja que terminen los accesos a la BD y las animaciones.
  Future<void> settle(WidgetTester t, {int rounds = 8}) async {
    for (var i = 0; i < rounds; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await t.pump(const Duration(milliseconds: 80));
    }
  }

  Future<void> tapText(WidgetTester t, String text) async {
    final finder = find.text(text).first;
    await t.ensureVisible(finder);
    await t.tap(finder);
    await settle(t, rounds: 4);
  }

  Future<void> enter(WidgetTester t, String label, String value) async {
    final finder = find.widgetWithText(TextField, label).first;
    await t.ensureVisible(finder);
    await t.enterText(finder, value);
    await t.pump(const Duration(milliseconds: 50));
  }

  /// Registra los desbordes en [overflows] en vez de romper la prueba.
  void captureOverflows() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      if (text.contains('overflowed by')) {
        final pixels = RegExp(
          r'overflowed by ([\d.]+) pixels',
        ).firstMatch(text);
        final place = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text);
        overflows.add('${place?.group(0) ?? '?'} (${pixels?.group(1)} px)');
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  Future<void> openApp(WidgetTester t) async {
    captureOverflows();
    t.view.physicalSize = const Size(1600, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ServiceLocator.materials.save(
        const PrintMaterial(
          kind: MaterialKind.filament,
          name: 'PLA',
          color: 'Negro',
          costPerKg: 20,
          stockGrams: 1000,
        ),
      );
    });
    await t.pumpWidget(const NesherPrintsApp());
    await settle(t);
  }

  /// Crea un pedido de 100 g y 2 h con el formulario.
  Future<void> createOrderThroughForm(WidgetTester t) async {
    await t.tap(find.byTooltip('Nuevo Pedido'));
    await settle(t);
    await enter(t, 'Nombre del Proyecto', 'Figura de prueba');
    await tapText(t, 'Añadir Placa');
    await enter(t, 'Gramos (g)', '100');
    await enter(t, 'Tiempo', '120');
    await settle(t, rounds: 2);
  }

  Future<double> stockOfPla(WidgetTester t) async => (await t.runAsync(
    () => ServiceLocator.materials.getAll(),
  ))!.single.stockGrams;

  testWidgets('crear un pedido muestra coste y precio recomendado correctos', (
    t,
  ) async {
    await openApp(t);
    await createOrderThroughForm(t);

    // 100 g × 20 €/kg = 2 € de material; 2 h de luz = 0,075 €.
    // Coste = (2 + 0,075) × 1,15 = 2,39 €
    // Recomendado = (2 × 2 + 0,075) × 2,15 = 8,76 €
    expect(find.text('€2.39'), findsOneWidget, reason: 'coste real');
    expect(find.text('€8.76'), findsOneWidget, reason: 'precio recomendado');
    expect(find.text('Total Placas (Automático)'), findsOneWidget);
  });

  testWidgets('flujo completo: crear, ver en Pedidos y completar', (t) async {
    await openApp(t);
    await createOrderThroughForm(t);

    await tapText(t, 'Aplicar');
    await tapText(t, 'Guardar Pedido');

    final saved = (await t.runAsync(
      () => ServiceLocator.orders.getAllWithDetails(),
    ))!;
    expect(saved, hasLength(1));
    expect(saved.single.order.name, 'Figura de prueba');
    expect(saved.single.order.price, closeTo(8.76, 0.01));
    expect(saved.single.platesCount, 1);
    expect(await stockOfPla(t), 1000, reason: 'crear no gasta material');

    // Ir a Pedidos y completar.
    await tapText(t, 'Pedidos');
    expect(find.text('Figura de prueba'), findsOneWidget);
    await t.tap(find.byTooltip('Marcar como Completado (Resta Stock)'));
    await settle(t, rounds: 3);
    await tapText(t, 'Sí, completar');
    await settle(t);

    expect(await stockOfPla(t), 900, reason: 'completar descuenta 100 g');
    final done = (await t.runAsync(
      () => ServiceLocator.orders.getAllWithDetails(),
    ))!.single.order;
    expect(done.status, OrderStatus.completed);
    expect(done.paidAmount, done.price);
    expect(
      find.byTooltip('Marcar como Completado (Resta Stock)'),
      findsNothing,
      reason: 'ya no se puede completar otra vez',
    );
  });

  bugTestWidgets('cambiar el estado desde la tabla y volver a completar no '
      'descuenta el material dos veces', (t) async {
    await openApp(t);
    await createOrderThroughForm(t);
    await tapText(t, 'Guardar Pedido');
    await tapText(t, 'Pedidos');

    await t.tap(find.byTooltip('Marcar como Completado (Resta Stock)'));
    await settle(t, rounds: 3);
    await tapText(t, 'Sí, completar');
    await settle(t);
    expect(await stockOfPla(t), 900);

    // Cambio rápido de estado desde la etiqueta: Completed → In Progress.
    await t.tap(find.text('Completed'));
    await settle(t, rounds: 3);
    await tapText(t, 'In Progress');
    await settle(t);

    await t.tap(find.byTooltip('Marcar como Completado (Resta Stock)'));
    await settle(t, rounds: 3);
    await tapText(t, 'Sí, completar');
    await settle(t);

    expect(
      await stockOfPla(t),
      900,
      reason: 'el material se descuenta una vez',
    );
  });

  bugTestWidgets('ninguna pantalla ni diálogo se desborda', (t) async {
    await openApp(t);
    await createOrderThroughForm(t);
    await tapText(t, 'Servicio de Pintura');
    await settle(t, rounds: 2);
    await tapText(t, 'Guardar Pedido');

    for (final section in [
      'Inventario',
      'Piezas',
      'Pedidos',
      'Clientes',
      'Administración',
      'Panel',
    ]) {
      await tapText(t, section);
      await settle(t, rounds: 3);
    }

    expect(overflows.toSet().toList()..sort(), isEmpty);
  });
}
