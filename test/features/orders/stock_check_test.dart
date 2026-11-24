import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/stock_check.dart';

void main() {
  test('el filamento no lleva stock: nunca avisa', () {
    final s = StockCheck.shortages(
      plates: [OrderPlate(name: 'P', grams: 500, minutes: 60, materialId: 1)],
      wasteByMaterial: const {},
      materials: const [
        PrintMaterial(
          id: 1,
          kind: MaterialKind.filament,
          name: 'PLA',
          color: 'Rojo',
          costPerKg: 20,
          stockGrams: 0,
        ),
      ],
    );
    expect(s, isEmpty);
  });

  PrintMaterial material(int id, double stock) => PrintMaterial(
    id: id,
    kind: MaterialKind.resin,
    name: 'Mat$id',
    color: 'Negro',
    costPerKg: 20,
    stockGrams: stock,
  );

  OrderPlate plate(int materialId, double grams) =>
      OrderPlate(name: 'P', grams: grams, minutes: 60, materialId: materialId);

  test('avisa cuando el stock no alcanza', () {
    final s = StockCheck.shortages(
      plates: [plate(1, 300)],
      wasteByMaterial: const {},
      materials: [material(1, 120)],
    );
    expect(s, hasLength(1));
    expect(s.single.materialName, 'Mat1');
    expect(s.single.neededGrams, 300);
    expect(s.single.availableGrams, 120);
  });

  test('suma las placas del mismo material', () {
    final s = StockCheck.shortages(
      plates: [plate(1, 100), plate(1, 100)],
      wasteByMaterial: const {},
      materials: [material(1, 150)],
    );
    expect(s.single.neededGrams, 200);
  });

  test('la merma ya registrada no se vuelve a contar', () {
    final s = StockCheck.shortages(
      plates: [plate(1, 300)],
      wasteByMaterial: const {1: 200},
      materials: [material(1, 120)],
    );
    expect(s, isEmpty, reason: 'solo se descontarán 100 g y hay 120');
  });

  test('con stock justo o de sobra no avisa', () {
    final s = StockCheck.shortages(
      plates: [plate(1, 100), plate(2, 50)],
      wasteByMaterial: const {},
      materials: [material(1, 100), material(2, 500)],
    );
    expect(s, isEmpty);
  });
}
