import 'package:flutter_test/flutter_test.dart';
import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

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
  test('sin pedidos todo es 0', () {
    final s = FinanceSummary.compute(
      orders: const [],
      materialCostPerKg: const {},
      legacyItems: const [],
      waste: const [],
    );
    expect(s.grossRevenue, 0);
    expect(s.netProfit, 0);
    expect(s.pendingCollection, 0);
    expect(s.monthly, isEmpty);
    expect(s.totalOrders, 0);
  });

  test('bruto, neto, pendiente, meses y estados', () {
    final s = FinanceSummary.compute(
      orders: [
        _o(1, OrderStatus.completed, price: 100, paid: 100, date: '2026-02-01'),
        _o(2, OrderStatus.shipped, price: 50, paid: 20, date: '2026-01-10'),
        _o(3, OrderStatus.inProgress, price: 80, paid: 30),
        _o(4, OrderStatus.draft, price: 999),
        _o(5, OrderStatus.canceled, price: 999),
      ],
      materialCostPerKg: {1: 20},
      // 500 g del pedido 1 a 20 €/kg = 10 € de coste
      legacyItems: const [
        LegacyOrderItem(orderId: 1, materialId: 1, grams: 500),
      ],
      // 250 g de merma a 20 €/kg = 5 €
      waste: const [WasteRecord(orderId: 3, materialId: 1, grams: 250)],
    );

    expect(s.grossRevenue, 150);
    expect(s.netProfit, 150 - 10 - 5);
    // Pendiente: envío (30) + en curso (50); borrador y cancelado no cuentan.
    expect(s.pendingCollection, 80);

    expect(s.monthly.keys, ['2026-01', '2026-02']);
    expect(s.monthly['2026-02']!.gross, 100);
    expect(s.monthly['2026-02']!.net, 90);
    expect(s.monthly['2026-01']!.net, 50);

    expect(s.statusCounts[OrderStatus.completed], 1);
    expect(s.statusCounts[OrderStatus.reserved], 0);
    expect(s.totalOrders, 5);
  });
}
