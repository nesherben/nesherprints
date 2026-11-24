import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/pending_list.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_costing.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

OrderSummary _o(
  int id,
  OrderStatus status, {
  double price = 100,
  double paid = 0,
  String date = '2026-03-15',
}) => OrderSummary(
  order: Order(
    id: id,
    name: 'P$id',
    price: price,
    paidAmount: paid,
    date: date,
    status: status,
  ),
);

void main() {
  group('FinanceSummary', () {
    test('sin pedidos todo es 0', () {
      final s = FinanceSummary.compute(
        orders: const [],
        costs: const {},
        materialCostPerKg: const {},
        waste: const [],
        profitGoal: 5000,
      );
      expect(s.grossRevenue, 0);
      expect(s.profit, 0);
      expect(s.ratio, 0);
      expect(s.pendingCollection, 0);
      expect(s.monthly, isEmpty);
      expect(s.totalOrders, 0);
      expect(s.goalProgress, 0);
    });

    test('facturado, beneficio, pendiente, meses y estados', () {
      final s = FinanceSummary.compute(
        orders: [
          _o(
            1,
            OrderStatus.completed,
            price: 100,
            paid: 100,
            date: '2026-02-01',
          ),
          _o(2, OrderStatus.shipped, price: 50, paid: 20, date: '2026-01-10'),
          _o(
            3,
            OrderStatus.inProgress,
            price: 80,
            paid: 30,
            date: '2026-02-20',
          ),
          _o(4, OrderStatus.draft, price: 999),
          _o(5, OrderStatus.canceled, price: 999),
          _o(6, OrderStatus.completed, price: 20, paid: 20, date: ''),
        ],
        costs: const {1: 40, 2: 30, 6: 5},
        materialCostPerKg: {1: 20},
        waste: const [
          WasteRecord(orderId: 3, materialId: 1, grams: 100),
          WasteRecord(orderId: 3, materialId: 1, grams: 50),
        ],
        profitGoal: 5000,
      );

      expect(s.completedOrders, 3);
      expect(s.grossRevenue, 170);
      expect(s.cost, 75);
      expect(s.profit, 95);
      expect(s.ratio, closeTo(95 / 170, 1e-9));
      expect(s.goalProgress, closeTo(95 / 5000, 1e-9));

      // Pendiente: envío (30) + en curso (50); borrador y cancelado no cuentan.
      expect(s.pendingCollection, 80);
      expect(s.pendingOrders.map((p) => p.id), [
        3,
        2,
      ], reason: 'mayor deuda 1.º');

      expect(s.monthly.keys, ['2026-01', '2026-02', kNoDateMonth]);
      final feb = s.monthly['2026-02']!;
      expect(feb.orders, 1);
      expect(feb.gross, 100);
      expect(feb.profit, 60);
      expect(feb.ratio, closeTo(0.6, 1e-9));

      expect(s.statusCounts[OrderStatus.completed], 2);
      expect(s.statusCounts[OrderStatus.reserved], 0);
      expect(s.totalOrders, 6);

      // Mermas: informativas, no se restan del beneficio.
      expect(s.wasteRecords, 2);
      expect(s.wasteGrams, 150);
      expect(s.wasteCost, closeTo(3, 1e-9));
    });

    test('un pedido sin coste conocido cuenta como coste 0', () {
      final s = FinanceSummary.compute(
        orders: [_o(1, OrderStatus.completed, price: 10, paid: 10)],
        costs: const {},
        materialCostPerKg: const {},
        waste: const [],
        profitGoal: 0,
      );
      expect(s.profit, 10);
      expect(s.goalProgress, 0, reason: 'sin objetivo no hay avance');
    });

    test('un beneficio negativo se muestra como pérdida', () {
      final s = FinanceSummary.compute(
        orders: [_o(1, OrderStatus.completed, price: 0, paid: 0)],
        costs: const {1: 7},
        materialCostPerKg: const {},
        waste: const [],
        profitGoal: 5000,
      );
      expect(s.profit, -7);
      expect(
        s.monthly.values.single.ratio,
        0,
        reason: 'sin facturación no hay margen',
      );
    });
  });

  group('OrderCosting', () {
    const settings = PricingSettings();
    const costPerKg = {1: 10.0};
    const plate = OrderPlate(
      name: 'A',
      grams: 166,
      minutes: 420,
      materialId: 1,
    );

    Order order({
      bool painted = false,
      double attempts = 1,
      double? override,
    }) => Order(
      id: 1,
      name: 'P',
      price: 10,
      date: '2026-11-01',
      status: OrderStatus.completed,
      isPainted: painted,
      attempts: attempts,
      costOverride: override,
    );

    double costOf(Order o, {List<OrderExtraLine> extras = const []}) =>
        OrderCosting.of(
          order: o,
          plates: const [plate],
          extras: extras,
          materialCostPerKg: costPerKg,
          settings: settings,
        );

    test('recalcula con la calculadora', () {
      // material 1,66 + máquina 7 h × 0,1375 + 1 placa = 3,6225
      expect(costOf(order()), closeTo(3.6225, 1e-9));
    });

    test('un coste fijo (pedido importado) sustituye al cálculo', () {
      expect(costOf(order(override: 12.34)), 12.34);
    });

    test(
      'piezas a su precio registrado e intentos; la pintura no es coste',
      () {
        final base = costOf(order());
        expect(costOf(order(painted: true)), closeTo(base, 1e-9));

        final withExtras = costOf(
          order(),
          extras: const [
            OrderExtraLine(extraId: 7, quantity: 4, unitPrice: 0.5),
          ],
        );
        expect(withExtras - base, closeTo(2, 1e-9));

        // Intentos 2: el material y la máquina se duplican.
        expect(costOf(order(attempts: 2)) - base, closeTo(1.66 + 0.9625, 1e-9));
      },
    );
  });

  group('PendingList.ageInDays', () {
    final now = DateTime(2026, 11, 24);

    test('días desde la fecha del pedido', () {
      expect(PendingList.ageInDays('2026-11-24', now), 0);
      expect(PendingList.ageInDays('2026-11-14', now), 10);
    });

    test('una fecha futura o inválida', () {
      expect(PendingList.ageInDays('2027-01-01', now), 0);
      expect(PendingList.ageInDays('', now), isNull);
      expect(PendingList.ageInDays('sin fecha', now), isNull);
    });
  });
}
