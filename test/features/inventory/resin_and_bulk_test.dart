import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/errors/app_exception.dart';
import 'package:nesherprints/features/inventory/data/material_repository.dart';
import 'package:nesherprints/features/inventory/domain/bulk_filaments.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/domain/resin_blend.dart';

void main() {
  group('ResinBlend', () {
    test('promedia el precio por los gramos de cada remesa', () {
      final price = ResinBlend.weightedPricePerKg(
        currentGrams: 1000,
        currentPricePerKg: 30,
        addedGrams: 1000,
        addedPricePerKg: 50,
      );
      expect(price, 40);
    });

    test('un tanque vacío o en negativo toma el precio de lo añadido', () {
      expect(
        ResinBlend.weightedPricePerKg(
          currentGrams: -200,
          currentPricePerKg: 30,
          addedGrams: 500,
          addedPricePerKg: 45,
        ),
        45,
      );
    });

    test('sin gramos totales se mantiene el precio', () {
      expect(
        ResinBlend.weightedPricePerKg(
          currentGrams: 0,
          currentPricePerKg: 30,
          addedGrams: 0,
          addedPricePerKg: 99,
        ),
        30,
      );
    });

    test('capacidad del tanque y nivel', () {
      expect(ResinBlend.tankCapacity(1000), 5000);
      expect(ResinBlend.tankCapacity(5200), 6000);
      expect(ResinBlend.level(2500), 0.5);
      expect(ResinBlend.level(-10), 0);
      expect(ResinBlend.level(9000), 1);
    });
  });

  group('BulkFilaments.parse', () {
    test('una línea por color, con precio propio opcional', () {
      final r = BulkFilaments.parse('Rojo\nAzul: 17,5\nVerde = 20 €\n');
      expect(r.map((c) => c.color), ['Rojo', 'Azul', 'Verde']);
      expect(r.map((c) => c.pricePerKg), [null, 17.5, 20]);
    });

    test('ignora vacías y repetidos sin distinguir mayúsculas', () {
      final r = BulkFilaments.parse('Rojo\n\n  \nROJO\nNegro; Blanco');
      expect(r.map((c) => c.color), ['Rojo', 'Negro', 'Blanco']);
    });

    test('un texto sin colores da una lista vacía', () {
      expect(BulkFilaments.parse('  \n\n'), isEmpty);
    });
  });

  group('MaterialRepository.addResin', () {
    late AppDatabase db;
    late MaterialRepository repo;

    setUp(() {
      db = AppDatabase.inMemory();
      repo = MaterialRepository(db);
    });

    tearDown(() => db.close());

    test('suma gramos y guarda el precio medio', () async {
      final id = await repo.save(
        const PrintMaterial(
          kind: MaterialKind.resin,
          name: 'Resina',
          color: 'Gris',
          costPerKg: 30,
          stockGrams: 1000,
        ),
      );
      await repo.addResin(id, grams: 1000, pricePerKg: 50);
      final m = (await repo.getAll()).single;
      expect(m.stockGrams, 2000);
      expect(m.costPerKg, 40);
    });

    test('rechaza gramos no positivos y materiales que no existen', () async {
      final id = await repo.save(
        const PrintMaterial(
          kind: MaterialKind.resin,
          name: 'Resina',
          color: '',
          costPerKg: 30,
          stockGrams: 100,
        ),
      );
      expect(
        () => repo.addResin(id, grams: 0, pricePerKg: 30),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repo.addResin(999, grams: 10, pricePerKg: 30),
        throwsA(isA<AppException>()),
      );
      expect((await repo.getAll()).single.stockGrams, 100);
    });
  });
}
