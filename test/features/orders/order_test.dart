import 'package:flutter_test/flutter_test.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

Order _order({
  OrderStatus status = OrderStatus.draft,
  double price = 100,
  double paid = 0,
}) => Order(
  id: 1,
  name: 'Figura',
  price: price,
  paidAmount: paid,
  date: '2026-11-23',
  status: status,
);

void main() {
  group('OrderStatus', () {
    test('se lee y escribe con el texto de la BD', () {
      for (final s in OrderStatus.values) {
        expect(OrderStatus.fromDb(s.dbValue), s);
      }
      expect(OrderStatus.inProgress.dbValue, 'In Progress');
      expect(OrderStatus.fromDb('???'), OrderStatus.draft);
    });

    test('reglas de cada estado', () {
      expect(OrderStatus.completed.isLocked, isTrue);
      expect(OrderStatus.shipped.isLocked, isTrue);
      expect(OrderStatus.inProgress.isLocked, isFalse);

      expect(OrderStatus.draft.canComplete, isTrue);
      expect(OrderStatus.canceled.canComplete, isFalse);
      expect(OrderStatus.shipped.canComplete, isFalse);

      expect(OrderStatus.manualChoices, isNot(contains(OrderStatus.completed)));
    });
  });

  group('Order', () {
    test('pendiente y saldado', () {
      expect(_order(paid: 40).pendingAmount, 60);
      expect(_order(paid: 40).isSettled, isFalse);
      expect(_order(paid: 100).isSettled, isTrue);
      expect(_order(status: OrderStatus.completed).isSettled, isTrue);
    });

    test('toMap/fromMap conserva los datos', () {
      final o = Order(
        id: 3,
        clientId: 2,
        name: 'Llavero',
        price: 12.5,
        paidAmount: 5,
        date: '2026-01-02',
        status: OrderStatus.reserved,
        isPainted: true,
        notes: 'urgente',
      );
      final back = Order.fromMap({'id': 3, ...o.toMap()});
      expect(back.clientId, 2);
      expect(back.status, OrderStatus.reserved);
      expect(back.isPainted, isTrue);
      expect(back.price, 12.5);
      expect(back.notes, 'urgente');
    });
  });

  group('OrderSummary.wasteRatePercent', () {
    OrderSummary summary({double? theoretical, double wasted = 0}) =>
        OrderSummary(
          order: _order(),
          theoreticalGrams: theoretical,
          wastedGrams: wasted,
        );

    test('merma sobre el peso teórico, sin límite', () {
      expect(summary(theoretical: 100, wasted: 50).wasteRatePercent, 50);
      expect(summary(theoretical: 100, wasted: 150).wasteRatePercent, 150);
    });

    test('sin peso teórico divide entre 1 g', () {
      expect(summary(wasted: 2).wasteRatePercent, 200);
      expect(summary(theoretical: 0, wasted: 2).wasteRatePercent, 200);
    });

    test('gravedad', () {
      expect(WasteSeverity.of(5), WasteSeverity.low);
      expect(WasteSeverity.of(10), WasteSeverity.low);
      expect(WasteSeverity.of(11), WasteSeverity.medium);
      expect(WasteSeverity.of(31), WasteSeverity.high);
    });
  });
}
