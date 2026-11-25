import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/inventory/domain/bambu_catalog.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';

void main() {
  test('el catálogo trae los tipos y colores de Bambu Lab', () {
    expect(BambuCatalog.types.length, greaterThanOrEqualTo(40));
    expect(BambuCatalog.colorCount, greaterThan(300));
    final basic = BambuCatalog.types.firstWhere((t) => t.name == 'PLA Basic');
    expect(basic.materialName, 'Bambu Lab PLA Basic');
    expect(basic.colors.any((c) => c.name == 'Orange'), isTrue);
    for (final t in BambuCatalog.types) {
      for (final c in t.colors) {
        expect(c.rgb, inInclusiveRange(0, 0xFFFFFF), reason: t.name);
      }
    }
  });

  test('suggestTypes autocompleta por inicio o contenido', () {
    final byStart = BambuCatalog.suggestTypes('bambu lab pla b');
    expect(byStart.first.name, 'PLA Basic');
    expect(
      BambuCatalog.suggestTypes('petg').map((t) => t.name),
      contains('PETG HF'),
    );
    expect(BambuCatalog.suggestTypes('  '), isEmpty);
  });

  test('typeOf reconoce el tipo más largo y exige mencionar a Bambu', () {
    expect(BambuCatalog.typeOf('Bambu Lab PLA Silk+')?.name, 'PLA Silk+');
    expect(BambuCatalog.typeOf('Bambu PLA Basic')?.name, 'PLA Basic');
    expect(BambuCatalog.typeOf('eSun PLA Basic'), isNull);
    expect(BambuCatalog.typeOf('Bambu algo raro'), isNull);
  });

  test(
    'toImport salta los repetidos y distingue el mismo nombre con otro RGB',
    () {
      final library = ColorLibrary.of([
        const LibraryColor('Black', 0x000000),
        const LibraryColor('Orange', 0xFF6A13),
      ]);
      final basic = BambuCatalog.types.firstWhere((t) => t.name == 'PLA Basic');
      final result = BambuCatalog.toImport([basic], library);
      final names = result.map((c) => c.name).toList();
      expect(names, isNot(contains('Orange')), reason: 'mismo nombre y RGB');
      expect(names.toSet().length, names.length, reason: 'sin repetidos');
      // Un nombre que ya existe con otro RGB entra con el tipo entre paréntesis.
      final other = BambuCatalog.toImport([
        basic,
      ], ColorLibrary.of([const LibraryColor('Orange', 0x123456)]));
      expect(other.map((c) => c.name), contains('Orange (PLA Basic)'));
    },
  );
}
