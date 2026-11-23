import 'package:nesherprints/core/constants.dart';
import 'package:nesherprints/data/database/db_helper.dart';

class MaterialRepository {
  final dbHelper = DatabaseHelper.instance;

  // CREAR
  Future<int> insertMaterial(Map<String, dynamic> material) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.materials} (
        ${DbColumns.materialId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.materialName} TEXT NOT NULL,
        color TEXT NOT NULL,
        ${DbColumns.materialType} TEXT NOT NULL,
        ${DbColumns.materialCostPerKg} REAL NOT NULL,
        stock_g REAL NOT NULL
      )
    ''');
    final db = await dbHelper.database;
    return await db.insert(DbTables.materials, material);
  }

  // LEER TODOS
  Future<List<Map<String, dynamic>>> getAllMaterials() async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.materials} (
        ${DbColumns.materialId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.materialName} TEXT NOT NULL,
        color TEXT NOT NULL,
        ${DbColumns.materialType} TEXT NOT NULL,
        ${DbColumns.materialCostPerKg} REAL NOT NULL,
        stock_g REAL NOT NULL
      )
    ''');
    final db = await dbHelper.database;
    return await db.query(
      DbTables.materials,
      orderBy: '${DbColumns.materialType} DESC, ${DbColumns.materialName} ASC',
    ); // Resina primero, luego alfabético
  }

  // ACTUALIZAR
  Future<int> updateMaterial(Map<String, dynamic> material) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.materials} (
        ${DbColumns.materialId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.materialName} TEXT NOT NULL,
        color TEXT NOT NULL,
        ${DbColumns.materialType} TEXT NOT NULL,
        ${DbColumns.materialCostPerKg} REAL NOT NULL,
        stock_g REAL NOT NULL
      )
    ''');
    final db = await dbHelper.database;
    return await db.update(
      DbTables.materials,
      material,
      where: '${DbColumns.materialId} = ?',
      whereArgs: [material['id']],
    );
  }

  // BORRAR
  Future<int> deleteMaterial(int id) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.materials} (
        ${DbColumns.materialId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.materialName} TEXT NOT NULL,
        color TEXT NOT NULL,
        ${DbColumns.materialType} TEXT NOT NULL,
        ${DbColumns.materialCostPerKg} REAL NOT NULL,
        stock_g REAL NOT NULL
      )
    ''');
    final db = await dbHelper.database;
    return await db.delete(
      DbTables.materials,
      where: '${DbColumns.materialId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> reduceStock(int id, double amountUsed) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.materials} (
        ${DbColumns.materialId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.materialName} TEXT NOT NULL,
        color TEXT NOT NULL,
        ${DbColumns.materialType} TEXT NOT NULL,
        ${DbColumns.materialCostPerKg} REAL NOT NULL,
        stock_g REAL NOT NULL
      )
    ''');
    final db = await dbHelper.database;
    // Con rawUpdate le decimos a SQLite: "Coge el stock actual y réstale esta cantidad"
    await db.rawUpdate(
      'UPDATE ${DbTables.materials} SET stock_g = stock_g - ? WHERE ${DbColumns.materialId} = ?',
      [amountUsed, id],
    );
  }
}
