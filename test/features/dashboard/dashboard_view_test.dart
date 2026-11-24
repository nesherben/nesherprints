import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/dashboard/presentation/dashboard_view.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

void main() {
  late AppDatabase db;
  late List<String> overflows;

  setUp(() {
    db = AppDatabase.inMemory();
    ServiceLocator.useDatabase(db);
    overflows = [];
  });

  tearDown(() => db.close());

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
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
        overflows.add(
          RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text)?.group(0) ?? '?',
        );
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  Future<void> pumpDashboard(
    WidgetTester t, {
    required Size size,
    bool withData = true,
  }) async {
    captureOverflows();
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final orders = await t.runAsync(() async {
      if (withData) {
        final material = await ServiceLocator.materials.save(
          const PrintMaterial(
            kind: MaterialKind.filament,
            name: 'PLA',
            color: 'Negro',
            costPerKg: 20,
            stockGrams: 1000,
          ),
        );
        final id = await ServiceLocator.orders.create(
          const Order(
            name: 'Figura',
            price: 100,
            paidAmount: 0,
            date: '2026-11-05',
            status: OrderStatus.inProgress,
          ),
          plates: [
            OrderPlate(
              name: 'Base',
              grams: 100,
              minutes: 120,
              materialId: material,
            ),
          ],
        );
        await ServiceLocator.orders.complete(id);
        await ServiceLocator.orders.create(
          const Order(
            name: 'Pendiente',
            price: 40,
            paidAmount: 10,
            date: '2026-11-10',
            status: OrderStatus.reserved,
          ),
          plates: const [],
        );
      }
      return ServiceLocator.orders.getAllWithDetails();
    });
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: DashboardView(orders: orders!)),
      ),
    );
    await settle(t);
  }

  testWidgets('muestra facturado, beneficio real, pendiente, objetivo y mes', (
    t,
  ) async {
    await pumpDashboard(t, size: const Size(1600, 1000));

    // Facturado 100 €; coste (2 + 0,075) × 1,15 = 2,386 € → beneficio 97,61 €.
    expect(find.text('Facturado'), findsWidgets);
    expect(find.text('€100.00'), findsWidgets);
    expect(find.text('€97.61'), findsWidgets);
    // Pendiente: 100 € cobrados al completar + 30 € que faltan del reservado.
    expect(find.text('€30.00'), findsWidgets);
    expect(find.text('1 pedido por cobrar'), findsOneWidget);
    // Objetivo: 97,61 / 5.000 ≈ 2 %.
    expect(find.text('2 %'), findsOneWidget);
    expect(find.text('nov 2026'), findsWidgets);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(overflows, isEmpty);
  });

  testWidgets('sin pedidos muestra ceros y estados vacíos', (t) async {
    await pumpDashboard(t, size: const Size(1600, 1000), withData: false);

    expect(find.text('€0.00'), findsWidgets);
    expect(find.text('Sin datos'), findsWidgets);
    expect(find.text('Todo cobrado'), findsOneWidget);
    expect(overflows, isEmpty);
  });

  testWidgets('en ventana estrecha se apila sin desbordes', (t) async {
    await pumpDashboard(t, size: const Size(420, 900));

    expect(find.text('Facturado'), findsWidgets);
    expect(overflows, isEmpty);
  });
}
