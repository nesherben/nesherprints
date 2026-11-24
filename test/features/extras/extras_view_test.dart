import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/extras/presentation/extras_view.dart';

/// Pantalla de Piezas sobre una base de datos en memoria. Los accesos a la BD
/// usan un hilo real, de ahí `runAsync` al esperar.
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

  Future<List<Extra>> stored(WidgetTester t) async =>
      (await t.runAsync(() => ServiceLocator.extras.getAll()))!;

  Future<void> seed(WidgetTester t, List<Extra> extras) async {
    await t.runAsync(() async {
      for (final e in extras) {
        await ServiceLocator.extras.save(e);
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
    await t.runAsync(() => ServiceLocator.extras.getAll());
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: ExtrasView()),
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

  const keychain = Extra(name: 'Llavero', unitPrice: 0.5, stock: 20);
  const clicker = Extra(name: 'Clicker', unitPrice: 2, stock: 3);
  const soldOut = Extra(name: 'Imán', unitPrice: 1, stock: 0);
  const negative = Extra(name: 'Anilla', unitPrice: 1, stock: -2);

  testWidgets('muestra las piezas, el resumen y los avisos de stock', (
    t,
  ) async {
    await seed(t, [keychain, clicker, soldOut, negative]);
    await openView(t);

    for (final name in ['Llavero', 'Clicker', 'Imán', 'Anilla']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('20 uds'), findsOneWidget);
    expect(find.text('Pocas unidades'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);
    expect(find.text('Stock negativo'), findsOneWidget);
    // Valor = 0,5 × 20 + 2 × 3 = 16 (los stocks ≤ 0 no cuentan).
    expect(find.text('€16.00'), findsOneWidget);
  });

  testWidgets('sin piezas muestra el estado vacío con acción', (t) async {
    await openView(t);

    expect(find.text('Aún no hay piezas'), findsOneWidget);
    await tapText(t, 'Añadir Piezas');
    expect(find.text('Añadir Pieza'), findsOneWidget);
  });

  testWidgets('el buscador filtra por nombre', (t) async {
    await seed(t, [keychain, clicker]);
    await openView(t);

    await t.enterText(find.byType(TextField), 'click');
    await settle(t, rounds: 2);
    expect(find.text('Clicker'), findsOneWidget);
    expect(find.text('Llavero'), findsNothing);

    await t.enterText(find.byType(TextField), 'zzz');
    await settle(t, rounds: 2);
    expect(find.text('Sin resultados'), findsOneWidget);

    await t.tap(find.byTooltip('Borrar búsqueda'));
    await settle(t, rounds: 2);
    expect(find.text('Llavero'), findsOneWidget);
    expect(find.text('Clicker'), findsOneWidget);
  });

  testWidgets('alta: valida los campos y calcula el precio unitario', (
    t,
  ) async {
    await openView(t);
    await tapText(t, 'Añadir Piezas');

    await tapText(t, 'Guardar');
    expect(find.text('Indica el nombre de la pieza'), findsOneWidget);
    expect(find.text('Indica unidades válidas (0 o más)'), findsOneWidget);
    expect(find.text('Indica un precio válido (0 o más)'), findsOneWidget);
    expect(await stored(t), isEmpty);

    await enter(t, 'Nombre', 'Soporte');
    await enter(t, 'Unidades por paquete', '10');
    await enter(t, 'Precio total del paquete (€)', '5');
    await tapText(t, 'Guardar');

    final saved = (await stored(t)).single;
    expect(saved.name, 'Soporte');
    expect(saved.stock, 10);
    expect(saved.unitPrice, 0.5);
    expect(find.text('Soporte'), findsOneWidget);
  });

  testWidgets('edición: cambia el nombre y conserva el id', (t) async {
    await seed(t, [keychain]);
    await openView(t);
    final id = (await stored(t)).single.id;

    await t.tap(find.byTooltip('Editar'));
    await settle(t);
    await enter(t, 'Nombre', 'Llavero XL');
    await tapText(t, 'Guardar');

    final saved = (await stored(t)).single;
    expect(saved.id, id);
    expect(saved.name, 'Llavero XL');
    expect(saved.stock, 20);
  });

  testWidgets('sumar unidades: botón deshabilitado hasta tener datos', (
    t,
  ) async {
    await seed(t, [keychain]);
    await openView(t);

    await t.tap(find.byTooltip('Sumar unidades'));
    await settle(t);
    final apply = find.widgetWithText(ElevatedButton, 'Aplicar');
    expect(t.widget<ElevatedButton>(apply).onPressed, isNull);

    // Con unidades basta: un total vacío cuenta como 0 € (regalo).
    await enter(t, 'Unidades a añadir', '20');
    expect(t.widget<ElevatedButton>(apply).onPressed, isNotNull);
    await enter(t, 'Unidades a añadir', '0');
    expect(t.widget<ElevatedButton>(apply).onPressed, isNull);
    await enter(t, 'Unidades a añadir', '20');
    await enter(t, 'Precio total de estas unidades (€)', '30');
    expect(t.widget<ElevatedButton>(apply).onPressed, isNotNull);
    // (0,5 × 20 + 30) / 40 = 1 €/ud
    expect(find.text('€1.0000'), findsOneWidget);

    await tapText(t, 'Aplicar');
    final saved = (await stored(t)).single;
    expect(saved.stock, 40);
    expect(saved.unitPrice, 1);
  });

  testWidgets('borrar pide confirmación y cancelar no borra', (t) async {
    await seed(t, [keychain]);
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
    expect(find.text('Aún no hay piezas'), findsOneWidget);
  });

  for (final size in const [Size(1600, 1000), Size(420, 900)]) {
    testWidgets('sin desbordes a ${size.width.toInt()} px', (t) async {
      await seed(t, [
        keychain,
        clicker,
        soldOut,
        const Extra(
          name:
              'Una pieza con un nombre especialmente largo para comprobar el '
              'recorte del texto en la tarjeta',
          unitPrice: 12345.6789,
          stock: -123456,
        ),
      ]);
      await openView(t, size: size);
      expect(overflows, isEmpty, reason: 'lista');

      await t.tap(find.byTooltip('Sumar unidades').first);
      await settle(t);
      await enter(t, 'Unidades a añadir', '5');
      await enter(t, 'Precio total de estas unidades (€)', '99999.99');
      expect(overflows, isEmpty, reason: 'diálogo de sumar unidades');
      await tapText(t, 'Cancelar');

      await t.tap(find.byTooltip('Editar').first);
      await settle(t);
      await enter(t, 'Nombre', '');
      await tapText(t, 'Guardar');
      expect(overflows, isEmpty, reason: 'diálogo con errores de validación');
    });
  }
}
