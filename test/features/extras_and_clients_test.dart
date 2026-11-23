import 'package:flutter_test/flutter_test.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

void main() {
  group('ExtraPricing', () {
    test('precio unitario de un paquete', () {
      expect(ExtraPricing.unitPriceFromPackage(totalPrice: 10, units: 4), 2.5);
      expect(ExtraPricing.unitPriceFromPackage(totalPrice: 10, units: 0), 10);
    });

    test('total del paquete al editar', () {
      expect(
        ExtraPricing.packageTotal(
          const Extra(name: 'x', unitPrice: 2, stock: 5),
        ),
        10,
      );
      expect(
        ExtraPricing.packageTotal(const Extra(name: 'x', unitPrice: 2)),
        2,
      );
    });

    test('media ponderada al sumar stock', () {
      // 10 uds a 1 € + 10 uds por 30 € → 40 € / 20 uds = 2 €
      expect(
        ExtraPricing.weightedUnitPrice(
          currentStock: 10,
          currentUnitPrice: 1,
          addedUnits: 10,
          addedTotal: 30,
        ),
        2,
      );
      // Stock resultante ≤ 0: se mantiene el precio actual.
      expect(
        ExtraPricing.weightedUnitPrice(
          currentStock: -5,
          currentUnitPrice: 3,
          addedUnits: 2,
          addedTotal: 10,
        ),
        3,
      );
    });
  });

  group('Client.fromForm', () {
    test('todo vacío no crea cliente', () {
      expect(Client.fromForm(name: ' ', phone: '', email: ''), isNull);
    });

    test('sin nombre usa teléfono y luego email', () {
      expect(
        Client.fromForm(name: '', phone: '600', email: 'a@b')!.name,
        '600',
      );
      expect(Client.fromForm(name: '', phone: '', email: 'a@b')!.name, 'a@b');
    });

    test('recorta espacios', () {
      final c = Client.fromForm(name: ' Ana ', phone: ' 6 ', email: '')!;
      expect(c.name, 'Ana');
      expect(c.phone, '6');
    });
  });
}
