import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/app.dart';
import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Recorrido por las pantallas reales (toques y escritura simulados) sobre una
/// base de datos en memoria. Los accesos a la BD usan un hilo real, de ahí
/// `runAsync` al esperar.
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

  Future<void> tapTooltip(WidgetTester t, String tooltip) async {
    final finder = find.byTooltip(tooltip).first;
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
        // Cadena de padres del widget que desborda, en una línea.
        final creator = RegExp(
          r'creator: (.*?)(?:\n\s*parentData|\n\s*constraints)',
          dotAll: true,
        ).firstMatch(text)?.group(1)?.replaceAll(RegExp(r'\s+'), ' ');
        overflows.add(
          '${place?.group(0) ?? '?'} (${pixels?.group(1)} px) <- $creator',
        );
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  /// Abre la app con un material (PLA) ya creado. [seed] se ejecuta antes de
  /// arrancar, para que la lista de pedidos inicial ya incluya sus datos.
  Future<void> openApp(
    WidgetTester t, {
    Size size = const Size(1600, 1000),
    Future<void> Function()? seed,
  }) async {
    captureOverflows();
    t.view.physicalSize = size;
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
      await seed?.call();
    });
    await t.pumpWidget(const NesherPrintsApp());
    await settle(t);
  }

  /// Rellena el formulario de un pedido de 100 g y 2 h.
  Future<void> fillOrderForm(WidgetTester t) async {
    await enter(t, 'Nombre del Proyecto', 'Figura de prueba');
    await tapText(t, 'Añadir Placa');
    await enter(t, 'Gramos', '100');
    await enter(t, 'Tiempo', '480');
    await settle(t, rounds: 2);
  }

  Future<void> createOrderThroughForm(WidgetTester t) async {
    await tapTooltip(t, 'Nuevo pedido');
    await settle(t);
    await fillOrderForm(t);
  }

  Future<double> stockOfPla(WidgetTester t) async => (await t.runAsync(
    () => ServiceLocator.materials.getAll(),
  ))!.single.stockGrams;

  Future<List<OrderSummary>> allOrders(WidgetTester t) async =>
      (await t.runAsync(() => ServiceLocator.orders.getAllWithDetails()))!;

  /// Crea un pedido directamente en la BD (sin pasar por el formulario).
  Future<int> seedOrder({
    String name = 'Figura',
    List<OrderExtraLine> extras = const [],
  }) async {
    final materialId = (await ServiceLocator.materials.getAll()).single.id!;
    return ServiceLocator.orders.create(
      Order(
        name: name,
        price: 30,
        paidAmount: 10,
        date: '2026-11-20',
        status: OrderStatus.inProgress,
      ),
      plates: [
        OrderPlate(
          name: 'Base',
          grams: 100,
          minutes: 120,
          materialId: materialId,
        ),
      ],
      extras: extras,
    );
  }

  testWidgets('crear un pedido muestra coste y precio recomendado correctos', (
    t,
  ) async {
    await openApp(t);
    await createOrderThroughForm(t);

    // 100 g × 20 €/kg = 2 € de material; 8 h × 0,1375 €/h = 1,10 € de máquina;
    // 1 placa = 1 €. Coste 4,10 €; recomendado = 4,10 × 2,5 = 10,25 €.
    expect(find.text('4,10 €'), findsOneWidget, reason: 'coste real');
    expect(find.text('10,25 €'), findsOneWidget, reason: 'precio recomendado');
    expect(find.text('1 placa · 8 h · 100 g'), findsOneWidget);
  });

  testWidgets('flujo completo: crear, ver en Pedidos y completar', (t) async {
    await openApp(t);
    await createOrderThroughForm(t);

    await tapText(t, 'Aplicar');
    await tapText(t, 'Guardar pedido');

    final saved = await allOrders(t);
    expect(saved, hasLength(1));
    expect(saved.single.order.name, 'Figura de prueba');
    expect(saved.single.order.price, closeTo(10.25, 0.01));
    expect(saved.single.platesCount, 1);
    expect(await stockOfPla(t), 1000, reason: 'crear no gasta material');

    // Ir a Pedidos y completar.
    await tapText(t, 'Pedidos');
    expect(find.text('Figura de prueba'), findsOneWidget);
    await tapTooltip(t, 'Completar pedido (descuenta el material)');
    await tapText(t, 'Sí, completar');
    await settle(t);

    expect(await stockOfPla(t), 900, reason: 'completar descuenta 100 g');
    final done = (await allOrders(t)).single.order;
    expect(done.status, OrderStatus.completed);
    expect(done.paidAmount, done.price);
    expect(
      find.byTooltip('Completar pedido (descuenta el material)'),
      findsNothing,
      reason: 'ya no se puede completar otra vez',
    );
  });

  testWidgets('un pedido completado no se reabre: solo pasa a Enviado', (
    t,
  ) async {
    await openApp(t, seed: seedOrder);
    await tapText(t, 'Pedidos');
    await tapTooltip(t, 'Completar pedido (descuenta el material)');
    await tapText(t, 'Sí, completar');
    await settle(t);
    expect(await stockOfPla(t), 900);

    // El menú de la etiqueta solo ofrece «Enviado».
    await tapText(t, 'Completado');
    expect(find.text('En curso'), findsNothing);
    expect(find.text('Borrador'), findsNothing);
    await tapText(t, 'Enviado');
    await settle(t);

    final order = (await allOrders(t)).single.order;
    expect(order.status, OrderStatus.shipped);
    expect(
      await stockOfPla(t),
      900,
      reason: 'el material se descuenta una vez',
    );
  });

  testWidgets('guardar sin placas avisa y no cierra el formulario', (t) async {
    await openApp(t);
    await tapTooltip(t, 'Nuevo pedido');
    await settle(t);
    await enter(t, 'Nombre del Proyecto', 'Sin placas');
    await tapText(t, 'Guardar pedido');

    expect(find.textContaining('Añade al menos una placa'), findsOneWidget);
    expect(
      find.text('Guardar pedido'),
      findsOneWidget,
      reason: 'sigue abierto',
    );
    expect(await allOrders(t), isEmpty);
  });

  testWidgets('editar y guardar sin tocar conserva las piezas del pedido', (
    t,
  ) async {
    late int orderId;
    await openApp(
      t,
      seed: () async {
        final extraId = await ServiceLocator.extras.save(
          const Extra(name: 'Anilla', unitPrice: 0.5, stock: 10),
        );
        orderId = await seedOrder(
          extras: [OrderExtraLine(extraId: extraId, quantity: 2)],
        );
      },
    );

    await tapText(t, 'Pedidos');
    await tapText(t, 'Figura');
    await settle(t);
    await tapText(t, 'Guardar pedido');

    final lines = await t.runAsync(
      () => ServiceLocator.orders.getExtras(orderId),
    );
    expect(lines, hasLength(1), reason: 'las piezas se cargan y se conservan');
    expect(lines!.single.quantity, 2);
    final extras = await t.runAsync(() => ServiceLocator.extras.getAll());
    expect(extras!.single.stock, 8, reason: 'el stock no cambia al re-guardar');
  });

  testWidgets('duplicar un pedido abre el formulario con una copia', (t) async {
    await openApp(t, seed: () => seedOrder(name: 'Figura'));
    await tapText(t, 'Pedidos');
    await tapTooltip(t, 'Más acciones');
    await tapText(t, 'Duplicar');
    await settle(t);

    expect(find.text('Duplicar pedido'), findsOneWidget);
    expect(find.text('Figura (copia)'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Base'),
      findsOneWidget,
      reason: 'copia las placas',
    );
    await tapText(t, 'Guardar pedido');

    final orders = await allOrders(t);
    expect(orders, hasLength(2));
    expect(orders.first.order.name, 'Figura (copia)');
    expect(orders.first.order.status, OrderStatus.draft);
    expect(orders.first.order.paidAmount, 0);
  });

  testWidgets('eliminar un pedido pide confirmación', (t) async {
    await openApp(t, seed: seedOrder);
    await tapText(t, 'Pedidos');
    await tapTooltip(t, 'Más acciones');
    await tapText(t, 'Eliminar');
    expect(find.text('Eliminar pedido'), findsOneWidget);
    await tapText(t, 'Cancelar');
    if (find.text('Descartar').evaluate().isNotEmpty) {
      await tapText(t, 'Descartar'); // había cambios sin guardar
    }
    expect(await allOrders(t), hasLength(1));

    await tapTooltip(t, 'Más acciones');
    await tapText(t, 'Eliminar');
    final confirm = find.widgetWithText(ElevatedButton, 'Eliminar');
    await t.tap(confirm);
    await settle(t);
    expect(await allOrders(t), isEmpty);
  });

  Future<void> visitEverything(WidgetTester t) async {
    await createOrderThroughForm(t);
    await tapText(t, 'Servicio de Pintura');
    await settle(t, rounds: 2);
    await tapText(t, 'Guardar pedido');
  }

  testWidgets('ninguna pantalla ni diálogo se desborda (escritorio)', (
    t,
  ) async {
    await openApp(t, seed: seedOrder);
    await visitEverything(t);
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

  testWidgets('ninguna pantalla ni diálogo se desborda (móvil)', (t) async {
    await openApp(t, size: const Size(420, 900), seed: seedOrder);
    await tapTooltip(t, 'Nuevo pedido');
    await settle(t);
    await fillOrderForm(t);
    await tapText(t, 'Servicio de Pintura');
    await settle(t, rounds: 2);
    await tapText(t, 'Cancelar');
    if (find.text('Descartar').evaluate().isNotEmpty) {
      await tapText(t, 'Descartar'); // había cambios sin guardar
    }

    for (final section in [
      'Inventario',
      'Piezas',
      'Pedidos',
      'Clientes',
      'Ajustes',
      'Panel',
    ]) {
      await tapText(t, section);
      await settle(t, rounds: 3);
    }
    expect(overflows.toSet().toList()..sort(), isEmpty);
  });
}
