import 'dart:math' as math;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/errors/app_exception.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/domain/resin_blend.dart';

class MaterialRepository {
  MaterialRepository(this._db);

  final AppDatabase _db;

  /// Todos los materiales: resinas primero, luego por nombre.
  Future<List<PrintMaterial>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      MaterialsTable.name,
      orderBy:
          '${MaterialsTable.type} DESC, ${MaterialsTable.materialName} ASC',
    );
    return rows.map(PrintMaterial.fromMap).toList();
  }

  /// Inserta o actualiza según tenga `id`. Devuelve el id del material.
  Future<int> save(PrintMaterial material) async {
    final db = await _db.database;
    if (material.id == null) {
      return db.insert(MaterialsTable.name, material.toMap());
    }
    await db.update(
      MaterialsTable.name,
      material.toMap(),
      where: '${MaterialsTable.id} = ?',
      whereArgs: [material.id],
    );
    return material.id!;
  }

  /// Añade resina al tanque: suma los gramos y promedia el precio por kilo
  /// con lo que ya había. Atómico.
  Future<void> addResin(
    int id, {
    required double grams,
    required double pricePerKg,
  }) async {
    if (grams <= 0 || pricePerKg < 0 || grams.isNaN || pricePerKg.isNaN) {
      throw const AppException(
        'Indica los gramos (más de 0) y un precio válido.',
      );
    }
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        MaterialsTable.name,
        where: '${MaterialsTable.id} = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) throw const AppException('El material ya no existe.');
      final current = PrintMaterial.fromMap(rows.first);
      await txn.update(
        MaterialsTable.name,
        {
          MaterialsTable.stockGrams: math.max(0.0, current.stockGrams) + grams,
          MaterialsTable.costPerKg: ResinBlend.weightedPricePerKg(
            currentGrams: current.stockGrams,
            currentPricePerKg: current.costPerKg,
            addedGrams: grams,
            addedPricePerKg: pricePerKg,
          ),
        },
        where: '${MaterialsTable.id} = ?',
        whereArgs: [id],
      );
    });
  }

  /// Deja una sola resina (la más antigua) con el total de gramos y el precio
  /// medio de todas; los pedidos que usaban las demás pasan a la que queda.
  /// Devuelve si hubo algo que fusionar.
  Future<bool> mergeResins() async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final resins = [
        for (final r in await txn.query(
          MaterialsTable.name,
          where: '${MaterialsTable.type} = ?',
          whereArgs: [MaterialKind.resin.dbValue],
          orderBy: '${MaterialsTable.id} ASC',
        ))
          PrintMaterial.fromMap(r),
      ];
      if (resins.length < 2) return false;
      final main = resins.first;
      var grams = math.max(0.0, main.stockGrams);
      var price = main.costPerKg;
      for (final other in resins.skip(1)) {
        price = ResinBlend.weightedPricePerKg(
          currentGrams: grams,
          currentPricePerKg: price,
          addedGrams: math.max(0.0, other.stockGrams),
          addedPricePerKg: other.costPerKg,
        );
        grams += math.max(0.0, other.stockGrams);
        for (final table in [
          '${OrderPlatesTable.name}:${OrderPlatesTable.materialId}',
          '${OrderWasteTable.name}:${OrderWasteTable.materialId}',
          '${OrderItemsTable.name}:${OrderItemsTable.materialId}',
        ]) {
          final parts = table.split(':');
          await txn.rawUpdate(
            'UPDATE ${parts[0]} SET ${parts[1]} = ? WHERE ${parts[1]} = ?',
            [main.id, other.id],
          );
        }
        await txn.delete(
          MaterialsTable.name,
          where: '${MaterialsTable.id} = ?',
          whereArgs: [other.id],
        );
      }
      await txn.update(
        MaterialsTable.name,
        {MaterialsTable.stockGrams: grams, MaterialsTable.costPerKg: price},
        where: '${MaterialsTable.id} = ?',
        whereArgs: [main.id],
      );
      return true;
    });
  }

  /// Número de placas de pedidos que usan el material.
  Future<int> usageCount(int id) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM ${OrderPlatesTable.name} '
      'WHERE ${OrderPlatesTable.materialId} = ?',
      [id],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Vuelve a insertar un material borrado con su mismo id (deshacer).
  Future<void> restore(PrintMaterial material) async {
    final db = await _db.database;
    await db.insert(
      MaterialsTable.name,
      material.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(
      MaterialsTable.name,
      where: '${MaterialsTable.id} = ?',
      whereArgs: [id],
    );
  }
}
