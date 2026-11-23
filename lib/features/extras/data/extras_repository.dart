import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/errors/app_exception.dart';
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

  /// Suma unidades compradas y recalcula el precio unitario (media ponderada)
  /// leyendo el stock y el precio **actuales** de la base de datos, así que
  /// no pisa cambios hechos mientras la pantalla estaba abierta.
  Future<void> addStock(
    int extraId, {
    required int units,
    required double totalPrice,
  }) async {
    if (units <= 0 || totalPrice < 0 || totalPrice.isNaN) {
      throw const AppException(
        'Indica unidades (más de 0) y un precio válido.',
      );
    }
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        ExtrasTable.name,
        where: '${ExtrasTable.id} = ?',
        whereArgs: [extraId],
      );
      if (rows.isEmpty) throw const AppException('La pieza ya no existe.');
      final current = Extra.fromMap(rows.first);
      await txn.update(
        ExtrasTable.name,
        {
          ExtrasTable.stock: current.stock + units,
          ExtrasTable.price: ExtraPricing.weightedUnitPrice(
            currentStock: current.stock,
            currentUnitPrice: current.unitPrice,
            addedUnits: units,
            addedTotal: totalPrice,
          ),
        },
        where: '${ExtrasTable.id} = ?',
        whereArgs: [extraId],
      );
    });
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
