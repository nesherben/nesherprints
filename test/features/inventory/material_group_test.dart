import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/inventory/domain/material_group.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';

PrintMaterial _m(String name, String color, double stock) => PrintMaterial(
  kind: MaterialKind.filament,
  name: name,
  color: color,
  costPerKg: 20,
  stockGrams: stock,
);

void main() {
  test('agrupa por nombre sin distinguir mayúsculas', () {
    final groups = MaterialGroup.group([
      _m('PLA eSun', 'Negro', 500),
      _m('pla esun', 'Blanco', 300),
      _m('PETG', 'Gris', 100),
    ]);
    expect(groups.map((g) => g.name), ['PETG', 'PLA eSun']);
    expect(groups.last.materials.map((m) => m.color), ['Blanco', 'Negro']);
  });

  test('los grupos van por orden alfabético', () {
    final groups = MaterialGroup.group([
      _m('Antiguo', 'A', 0),
      _m('Antiguo', 'B', -50),
      _m('Zeta', 'A', 10),
    ]);
    expect(groups.map((g) => g.name), ['Antiguo', 'Zeta']);
    expect(groups.first.hasStock, isFalse);
  });

  test('el stock total no resta los negativos', () {
    final group = MaterialGroup.group([
      _m('PLA', 'A', 400),
      _m('PLA', 'B', -180),
    ]).single;
    expect(group.totalGrams, 400);
  });

  test('agotado y bajo son estados distintos', () {
    expect(_m('x', 'y', 0).isOutOfStock, isTrue);
    expect(_m('x', 'y', 0).isLowStock, isFalse);
    expect(_m('x', 'y', 50).isLowStock, isTrue);
    expect(_m('x', 'y', 500).isLowStock, isFalse);
    expect(_m('x', 'y', -5).isOutOfStock, isTrue);
  });
}
