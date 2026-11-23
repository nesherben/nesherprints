import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';

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

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(
      MaterialsTable.name,
      where: '${MaterialsTable.id} = ?',
      whereArgs: [id],
    );
  }
}
