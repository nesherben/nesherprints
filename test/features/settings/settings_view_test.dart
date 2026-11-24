import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/constants/app_constants.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/settings/presentation/settings_view.dart';

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
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await t.pump(const Duration(milliseconds: 80));
    }
  }

  void captureOverflows() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      if (text.contains('overflowed by')) {
        final place = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text);
        overflows.add(place?.group(0) ?? '?');
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  Future<void> open(
    WidgetTester t, {
    Size size = const Size(1600, 1000),
  }) async {
    captureOverflows();
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    // Abre la BD fuera del reloj simulado.
    await t.runAsync(() => ServiceLocator.settings.getPricingSettings());
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: SettingsView()),
      ),
    );
    await settle(t);
  }

  Finder field(String settingKey) => find.byKey(ValueKey(settingKey));

  Finder profitField() => field(SettingKeys.profitMargin);

  Future<void> enter(WidgetTester t, Finder f, String value) async {
    await t.ensureVisible(f);
    await t.enterText(f, value);
    await t.pump(const Duration(milliseconds: 50));
  }

  ElevatedButton saveButton(WidgetTester t) =>
      t.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Guardar'));

  String textOf(WidgetTester t, Finder f) =>
      t.widget<TextField>(f).controller!.text;

  testWidgets('carga los valores por defecto y Guardar está deshabilitado', (
    t,
  ) async {
    await open(t);
    expect(textOf(t, profitField()), '15');
    expect(textOf(t, field(SettingKeys.kwhCost)), '0.0375');
    expect(textOf(t, field(SettingKeys.profitGoal)), '5000');
    expect(find.text('Todo guardado'), findsOneWidget);
    expect(saveButton(t).onPressed, isNull);
    expect(find.byTooltip('Restaurar este valor'), findsNothing);
    // Ejemplo con los valores de fábrica.
    expect(find.text('€2.39'), findsOneWidget);
    expect(find.text('€8.76'), findsOneWidget);
  });

  testWidgets('un valor inválido muestra error y deshabilita Guardar', (
    t,
  ) async {
    await open(t);
    await enter(t, profitField(), '20');
    expect(saveButton(t).onPressed, isNotNull);
    expect(find.text('Cambios sin guardar'), findsOneWidget);

    await enter(t, profitField(), '');
    expect(find.text('Obligatorio'), findsOneWidget);
    expect(saveButton(t).onPressed, isNull);
    expect(textOf(t, profitField()), '', reason: 'no se sustituye en silencio');

    await enter(t, profitField(), '1500');
    expect(find.text('Máximo 1000'), findsOneWidget);
    expect(saveButton(t).onPressed, isNull);
  });

  testWidgets('guardar persiste los ajustes y vuelve a "guardado"', (t) async {
    await open(t);
    await enter(t, profitField(), '20,5');
    await t.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await settle(t);

    final saved = (await t.runAsync(
      () => ServiceLocator.settings.getPricingSettings(),
    ))!;
    expect(saved.profitMarginPercent, 20.5);
    expect(saved.safetyMarginPercent, FinanceDefaults.safetyMarginPercent);
    expect(saved.paintDetailFewCost, FinanceDefaults.paintDetailFewCost);
    expect(find.text('Todo guardado'), findsOneWidget);
    expect(saveButton(t).onPressed, isNull);
  });

  testWidgets('restaurar valores por defecto pide confirmación', (t) async {
    await open(t);
    await enter(t, profitField(), '40');
    expect(find.byTooltip('Restaurar este valor'), findsOneWidget);

    await t.tap(find.text('Restaurar valores por defecto'));
    await settle(t, rounds: 3);
    expect(find.text('Restaurar'), findsOneWidget);
    await t.tap(find.text('Cancelar'));
    await settle(t, rounds: 3);
    expect(textOf(t, profitField()), '40');

    await t.tap(find.text('Restaurar valores por defecto'));
    await settle(t, rounds: 3);
    await t.tap(find.text('Restaurar'));
    await settle(t, rounds: 3);
    expect(textOf(t, profitField()), '15');
    // Los valores por defecto coinciden con lo guardado: sin cambios.
    expect(find.text('Todo guardado'), findsOneWidget);
  });

  testWidgets('el botón restaurar de un campo recupera su valor', (t) async {
    await open(t);
    await enter(t, profitField(), '40');
    await t.ensureVisible(find.byTooltip('Restaurar este valor'));
    await t.tap(find.byTooltip('Restaurar este valor'));
    await t.pump();
    expect(textOf(t, profitField()), '15');
  });

  testWidgets('el ejemplo en vivo cambia al editar el margen', (t) async {
    await open(t);
    expect(find.text('€8.76'), findsOneWidget);
    await enter(t, profitField(), '0');
    // (2 × 2 + 0,075) × 2 = 8,15 €; el coste no depende de este margen.
    expect(find.text('€8.15'), findsOneWidget);
    expect(find.text('€2.39'), findsOneWidget);

    await enter(t, profitField(), '');
    expect(
      find.text('Corrige los campos con error para ver el ejemplo.'),
      findsOneWidget,
    );
  });

  for (final size in const [Size(1600, 1000), Size(420, 900)]) {
    testWidgets(
      'sin desbordes a ${size.width.toInt()}×${size.height.toInt()}',
      (t) async {
        await open(t, size: size);
        await enter(t, profitField(), '');
        await settle(t, rounds: 2);
        expect(overflows, isEmpty);
      },
    );
  }
}
