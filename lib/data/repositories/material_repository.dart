import '../database/db_helper.dart';

class MaterialRepository {
  final dbHelper = DatabaseHelper.instance;

  // CREAR
  Future<int> insertMaterial(Map<String, dynamic> material) async {
    final db = await dbHelper.database;
    return await db.insert('materials', material);
  }

  // LEER TODOS
  Future<List<Map<String, dynamic>>> getAllMaterials() async {
    final db = await dbHelper.database;
    return await db.query(
      'materials',
      orderBy: 'type DESC, name ASC',
    ); // Resina primero, luego alfabético
  }

  // ACTUALIZAR
  Future<int> updateMaterial(Map<String, dynamic> material) async {
    final db = await dbHelper.database;
    return await db.update(
      'materials',
      material,
      where: 'id = ?',
      whereArgs: [material['id']],
    );
  }

  // BORRAR
  Future<int> deleteMaterial(int id) async {
    final db = await dbHelper.database;
    return await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reduceStock(int id, double amountUsed) async {
    final db = await dbHelper.database;
    // Con rawUpdate le decimos a SQLite: "Coge el stock actual y réstale esta cantidad"
    await db.rawUpdate(
      'UPDATE materials SET stock_g = stock_g - ? WHERE id = ?',
      [amountUsed, id],
    );
  }
}
