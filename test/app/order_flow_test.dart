import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/app.dart';
import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
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

  testWidgets('alta rápida crea un borrador y el precio se edita en la fila', (
    t,
  ) async {
    await openApp(t, seed: () => seedOrder(name: 'Figura'));
    await tapText(t, 'Pedidos');

    Finder hint(String text) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == text,
    );
    await t.enterText(hint('Pedido rápido: nombre del proyecto…'), 'Llavero X');
    await t.enterText(hint('Precio'), '12,5');
    await t.pump();
    await t.tap(find.widgetWithText(ElevatedButton, 'Añadir'));
    await settle(t, rounds: 4);

    var orders = await allOrders(t);
    expect(orders, hasLength(2));
    final created = orders.firstWhere((o) => o.order.name == 'Llavero X');
    expect(created.order.status, OrderStatus.draft);
    expect(created.order.price, 12.5);

    // Edición del precio en la propia fila.
    await t.tap(find.text('12,50 €').first);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, '20');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t, rounds: 4);
    orders = await allOrders(t);
    expect(
      orders.firstWhere((o) => o.order.name == 'Llavero X').order.price,
      20,
    );
  });

  testWidgets('el Panel lleva a Pedidos: KPI «Pendiente» y pedido pendiente', (
    t,
  ) async {
    await openApp(t, seed: () => seedOrder(name: 'Figura'));

    // Pulsar la tarjeta «Pendiente de cobro» abre Pedidos ya filtrado.
    await tapText(t, 'Pendiente de Cobro');
    await settle(t, rounds: 3);
    final chip = find.widgetWithText(FilterChip, 'Por cobrar · 1');
    expect(chip, findsOneWidget);
    expect(t.widget<FilterChip>(chip).selected, isTrue);

    // Pulsar un pedido de la lista de pendientes abre su formulario.
    await tapText(t, 'Panel');
    await settle(t, rounds: 3);
    await tapText(t, 'Figura');
    await settle(t, rounds: 4);
    expect(find.text('Datos del pedido'), findsOneWidget);
  });

  testWidgets('el menú de columnas oculta y muestra columnas de la tabla', (
    t,
  ) async {
    await openApp(t, seed: () => seedOrder(name: 'Figura'));
    await tapText(t, 'Pedidos');
    await settle(t, rounds: 3);
    expect(find.text('FECHA'), findsOneWidget);

    await tapTooltip(t, 'Columnas de la tabla');
    await t.tap(find.text('Fecha').last);
    await settle(t, rounds: 3);
    expect(find.text('FECHA'), findsNothing);
    // La fecha pasa a ir bajo el nombre del proyecto.
    expect(find.text('2026-11-20'), findsOneWidget);

    await tapTooltip(t, 'Columnas de la tabla');
    await t.tap(find.text('Fecha').last);
    await settle(t, rounds: 3);
    expect(find.text('FECHA'), findsOneWidget);
  });

  testWidgets('Ctrl+K busca en toda la app y abre el pedido elegido', (
    t,
  ) async {
    await openApp(t, seed: () => seedOrder(name: 'Dragón rojo'));
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(t, rounds: 3);
    expect(
      find.text('Buscar pedidos, clientes, piezas o colores…'),
      findsOneWidget,
    );

    await t.enterText(find.byType(TextField).last, 'dragon');
    await settle(t, rounds: 2);
    expect(
      find.text('Sin resultados'),
      findsOneWidget,
      reason: 'sin tildes no',
    );
    await t.enterText(find.byType(TextField).last, 'drag');
    await settle(t, rounds: 2);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t, rounds: 4);

    expect(find.text('Datos del pedido'), findsOneWidget);
  });

  testWidgets('F1 abre la chuleta de atajos', (t) async {
    await openApp(t);
    await t.sendKeyEvent(LogicalKeyboardKey.f1);
    await settle(t, rounds: 3);
    expect(find.text('Atajos de teclado'), findsOneWidget);
    expect(find.text('Ctrl + N'), findsOneWidget);
  });

  testWidgets('«Guardar y nuevo» guarda y abre otro formulario vacío', (
    t,
  ) async {
    await openApp(t);
    await createOrderThroughForm(t);
    await tapText(t, 'Guardar y nuevo');
    await settle(t, rounds: 4);

    expect(await allOrders(t), hasLength(1));
    // Otro formulario, vacío y listo para escribir.
    expect(find.text('Datos del pedido'), findsOneWidget);
    final name = find.widgetWithText(TextFormField, 'Figura de prueba');
    expect(name, findsNothing, reason: 'el nuevo formulario está vacío');
  });

  testWidgets('con el teclado ↓ marca el pedido e Intro lo abre', (t) async {
    await openApp(t, seed: () => seedOrder(name: 'Figura'));
    await tapText(t, 'Pedidos');
    expect(find.text('Datos del pedido'), findsNothing);

    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(t, rounds: 4);

    expect(find.text('Datos del pedido'), findsOneWidget);
  });

  testWidgets('asignar cliente a los pedidos filtrados', (t) async {
    await openApp(
      t,
      seed: () async {
        await seedOrder(name: 'Llavero A');
        await seedOrder(name: 'Llavero B');
        await seedOrder(name: 'Otro');
        await ServiceLocator.clients.save(const Client(name: 'Ana'));
      },
    );
    await tapText(t, 'Pedidos');
    await t.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText ?? '').startsWith('Buscar por proyecto'),
      ),
      'llavero',
    );
    await settle(t, rounds: 3);
    await tapText(t, 'Asignar cliente a estos (2)');
    await t.tap(find.byType(DropdownButtonFormField<int>).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Ana').last);
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ElevatedButton, 'Asignar a 2 pedidos'));
    await settle(t, rounds: 4);

    final orders = await allOrders(t);
    expect(orders.where((o) => o.clientName == 'Ana'), hasLength(2));
    expect(orders.where((o) => o.clientName == null), hasLength(1));
  });

  testWidgets('duplicar un pedido abre el formulario con una copia', (t) async {
    await openApp(t, seed: () => seedOrder(name: 'Figura'));
    await tapText(t, 'Pedidos');
    await tapTooltip(t, 'Duplicar');
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
    await tapTooltip(t, 'Eliminar');
    expect(find.text('Eliminar pedido'), findsOneWidget);
    await tapText(t, 'Cancelar');
    if (find.text('Descartar').evaluate().isNotEmpty) {
      await tapText(t, 'Descartar'); // había cambios sin guardar
    }
    expect(await allOrders(t), hasLength(1));

    await tapTooltip(t, 'Eliminar');
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

  // Barrido de tamaños: móviles, tabletas en ambas orientaciones y ventanas de
  // escritorio, con las pantallas principales y el formulario de pedido.
  const sizes = [
    Size(320, 640),
    Size(360, 800),
    Size(412, 915),
    Size(600, 960),
    Size(719, 900),
    Size(720, 900),
    Size(800, 1280),
    Size(900, 700),
    Size(1024, 768),
    Size(1099, 700),
    Size(1100, 700),
    Size(1280, 720),
    Size(1366, 768),
    Size(1920, 1080),
    Size(2560, 1440),
  ];
  for (final size in sizes) {
    testWidgets(
      'sin desbordes a ${size.width.toInt()}x${size.height.toInt()}',
      (t) async {
        await openApp(t, size: size, seed: seedOrder);
        final compact = size.width < 720;
        final sections = [
          'Inventario',
          'Piezas',
          'Pedidos',
          'Clientes',
          compact ? 'Ajustes' : 'Administración',
          'Panel',
        ];
        for (final section in sections) {
          await tapText(t, section);
          await settle(t, rounds: 3);
        }
        // Formulario de pedido abierto y descartado.
        await tapText(t, 'Pedidos');
        await settle(t, rounds: 2);
        await tapTooltip(t, 'Nuevo pedido');
        await settle(t);
        await tapText(t, 'Cancelar');
        if (find.text('Descartar').evaluate().isNotEmpty) {
          await tapText(t, 'Descartar');
        }
        expect(overflows.toSet().toList()..sort(), isEmpty);
      },
    );
  }
}
