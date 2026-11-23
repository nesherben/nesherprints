import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

class ExtrasRepository {
  ExtrasRepository(this._db);

  final AppDatabase _db;

  /// Todas las piezas, en orden de creación.
  Future<List<Extra>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(ExtrasTable.name);
    return rows.map(Extra.fromMap).toList();
  }

  /// Inserta o actualiza según tenga `id`. Devuelve el id de la pieza.
  Future<int> save(Extra extra) async {
    final db = await _db.database;
    if (extra.id == null) {
      return db.insert(ExtrasTable.name, extra.toMap());
    }
    await db.update(
      ExtrasTable.name,
      extra.toMap(),
      where: '${ExtrasTable.id} = ?',
      whereArgs: [extra.id],
    );
    return extra.id!;
  }

  /// Suma unidades compradas y recalcula el precio unitario (media ponderada).
  Future<void> addStock(
    Extra extra, {
    required int units,
    required double totalPrice,
  }) async {
    final db = await _db.database;
    await db.update(
      ExtrasTable.name,
      {
        ExtrasTable.stock: extra.stock + units,
        ExtrasTable.price: ExtraPricing.weightedUnitPrice(
          currentStock: extra.stock,
          currentUnitPrice: extra.unitPrice,
          addedUnits: units,
          addedTotal: totalPrice,
        ),
      },
      where: '${ExtrasTable.id} = ?',
      whereArgs: [extra.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(
      ExtrasTable.name,
      where: '${ExtrasTable.id} = ?',
      whereArgs: [id],
    );
  }
}
