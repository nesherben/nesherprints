import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/clients/presentation/clients_view.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import '../../support/row_menu.dart';

/// Pantalla de Clientes sobre una base de datos en memoria. Los accesos a la
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

  Future<List<Client>> stored(WidgetTester t) async =>
      (await t.runAsync(() => ServiceLocator.clients.getAll()))!;

  /// Guarda los clientes y devuelve sus ids.
  Future<List<int>> seed(WidgetTester t, List<Client> clients) async =>
      (await t.runAsync(
        () async => [
          for (final c in clients) await ServiceLocator.clients.save(c),
        ],
      ))!;

  /// Crea un pedido; los completados se crean abiertos y se completan (no
  /// pueden nacer cerrados).
  Future<void> seedOrder(
    WidgetTester t,
    int clientId,
    OrderStatus status,
    double price,
    double paid,
  ) async {
    await t.runAsync(() async {
      final id = await ServiceLocator.orders.create(
        Order(
          clientId: clientId,
          name: 'Pedido',
          price: price,
          paidAmount: paid,
          date: '2026-11-23',
          status: status.isLocked ? OrderStatus.inProgress : status,
        ),
        plates: const [],
      );
      if (status == OrderStatus.completed) {
        await ServiceLocator.orders.complete(id);
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
    await t.runAsync(() => ServiceLocator.clients.getAll());
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: ClientsView()),
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

  const ana = Client(
    name: 'Ana López',
    phone: '600111222',
    email: 'ana@correo.com',
  );
  const beto = Client(name: 'Beto', phone: '611000111');

  testWidgets('muestra los clientes con contacto y estadísticas', (t) async {
    final ids = await seed(t, [ana, beto]);
    await seedOrder(t, ids[0], OrderStatus.completed, 40, 40);
    await seedOrder(t, ids[0], OrderStatus.inProgress, 50, 20);
    await seedOrder(t, ids[0], OrderStatus.canceled, 99, 0);
    await openView(t);

    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('600111222'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
    expect(find.text('AL'), findsOneWidget, reason: 'iniciales');
    expect(find.text('2 pedidos'), findsOneWidget);
    expect(find.text('40,00 €'), findsNWidgets(2), reason: 'resumen y tarjeta');
    expect(find.text('30,00 €'), findsNWidgets(2), reason: 'resumen y tarjeta');
    expect(find.text('0 pedidos'), findsOneWidget);
    expect(find.text('Al día'), findsOneWidget);
  });

  testWidgets('sin clientes muestra el estado vacío con acción', (t) async {
    await openView(t);

    expect(find.text('Aún no tienes clientes registrados.'), findsOneWidget);
    await tapText(t, 'Nuevo cliente');
    expect(find.text('Nombre / Alias'), findsOneWidget);
  });

  testWidgets('el buscador filtra por nombre, teléfono y email', (t) async {
    await seed(t, [ana, beto]);
    await openView(t);

    await t.enterText(find.byType(TextField), 'beto');
    await settle(t, rounds: 2);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('Ana López'), findsNothing);

    await t.enterText(find.byType(TextField), 'correo.com');
    await settle(t, rounds: 2);
    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('Beto'), findsNothing);

    await t.enterText(find.byType(TextField), '611000');
    await settle(t, rounds: 2);
    expect(find.text('Beto'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'zzz');
    await settle(t, rounds: 2);
    expect(find.text('Sin resultados'), findsOneWidget);

    await t.tap(find.byTooltip('Borrar búsqueda'));
    await settle(t, rounds: 2);
    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('Beto'), findsOneWidget);
  });

  testWidgets('alta: sin nombre se usa el teléfono; todo vacío no guarda', (
    t,
  ) async {
    await openView(t);
    await tapText(t, 'Nuevo cliente');
    await tapText(t, 'Guardar');
    expect(await stored(t), isEmpty);

    await tapText(t, 'Nuevo cliente');
    await enter(t, 'Teléfono (WhatsApp)', '622333444');
    await tapText(t, 'Guardar');

    final saved = (await stored(t)).single;
    expect(saved.name, '622333444');
    expect(saved.phone, '622333444');
    expect(find.text('622333444'), findsWidgets);
  });

  testWidgets('edición: cambia el nombre y conserva el id', (t) async {
    await seed(t, [ana]);
    await openView(t);
    final id = (await stored(t)).single.id;

    await tapRowMenu(t, 'Editar Cliente');
    await settle(t);
    await enter(t, 'Nombre / Alias', 'Ana Pérez');
    await tapText(t, 'Guardar');

    final saved = (await stored(t)).single;
    expect(saved.id, id);
    expect(saved.name, 'Ana Pérez');
    expect(saved.phone, '600111222');
    expect(find.text('Ana Pérez'), findsOneWidget);
  });

  testWidgets('copiar el teléfono lo deja en el portapapeles', (t) async {
    await seed(t, [ana]);
    await openView(t);

    String? clipboard;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await t.tap(find.byTooltip('Copiar teléfono'));
    await settle(t, rounds: 2);
    expect(clipboard, '600111222');
    expect(find.text('Copiado'), findsOneWidget);
  });

  for (final size in const [Size(1600, 1000), Size(420, 900)]) {
    testWidgets('sin desbordes a ${size.width.toInt()} px', (t) async {
      final ids = await seed(t, [
        ana,
        beto,
        const Client(
          name:
              'Un nombre de cliente especialmente largo para comprobar el '
              'recorte del texto en la tarjeta',
          phone: '+34 600 111 222 333 444 555 666 777 888 999 000 111',
          email:
              'una.direccion.de.correo.muy.larga@un-dominio-muy-largo.example.com',
        ),
      ]);
      await seedOrder(t, ids[2], OrderStatus.completed, 123456.78, 0);
      await openView(t, size: size);
      expect(overflows, isEmpty, reason: 'lista');

      await tapRowMenu(t, 'Editar Cliente');
      await settle(t);
      expect(overflows, isEmpty, reason: 'diálogo');
    });
  }
}
