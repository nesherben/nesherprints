import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/clients/domain/client_stats.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

OrderSummary _order({
  int? clientId,
  required OrderStatus status,
  double price = 100,
  double paid = 0,
}) => OrderSummary(
  order: Order(
    id: 1,
    clientId: clientId,
    name: 'P',
    price: price,
    paidAmount: paid,
    date: '2026-01-01',
    status: status,
  ),
);

void main() {
  test('sin pedidos no hay estadísticas', () {
    expect(ClientStats.fromOrders(const []), isEmpty);
  });

  test('agrupa por cliente e ignora pedidos sin cliente', () {
    final stats = ClientStats.fromOrders([
      _order(clientId: 1, status: OrderStatus.completed, price: 50, paid: 50),
      _order(clientId: 1, status: OrderStatus.shipped, price: 30, paid: 10),
      _order(clientId: 2, status: OrderStatus.inProgress, price: 20),
      _order(status: OrderStatus.completed, price: 99),
    ]);
    expect(stats.keys.toSet(), {1, 2});
    expect(stats[1]!.orderCount, 2);
    expect(stats[1]!.billed, 80);
    expect(stats[1]!.pending, 20);
    expect(stats[1]!.owes, isTrue);
    expect(stats[2]!.orderCount, 1);
    expect(stats[2]!.billed, 0);
    expect(stats[2]!.pending, 20);
  });

  test('cancelados no cuentan; borradores no generan deuda', () {
    final stats = ClientStats.fromOrders([
      _order(clientId: 1, status: OrderStatus.canceled, price: 40),
      _order(clientId: 1, status: OrderStatus.draft, price: 60),
    ]);
    expect(stats[1]!.orderCount, 1);
    expect(stats[1]!.billed, 0);
    expect(stats[1]!.pending, 0);
    expect(stats[1]!.owes, isFalse);
  });

  test('un cobro de más no resta deuda de otros pedidos', () {
    final stats = ClientStats.fromOrders([
      _order(clientId: 1, status: OrderStatus.completed, price: 10, paid: 15),
      _order(clientId: 1, status: OrderStatus.reserved, price: 30, paid: 10),
    ]);
    expect(stats[1]!.pending, 20);
  });
}
