import '../database/db_helper.dart';
import '../../core/constants.dart';

class ExtrasRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getAllExtras() async {
    // Ensure table exists for older DBs
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.extras} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        unit TEXT DEFAULT ''
      )
    ''');

    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DbTables.extras);
    return maps;
  }

  Future<int> insertExtra(Map<String, dynamic> extra) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.extras} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        unit TEXT DEFAULT ''
      )
    ''');
    final db = await dbHelper.database;
    return await db.insert(DbTables.extras, extra);
  }

  Future<int> updateExtra(int id, Map<String, dynamic> extra) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.extras} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        unit TEXT DEFAULT ''
      )
    ''');
    final db = await dbHelper.database;
    return await db.update(
      DbTables.extras,
      extra,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExtra(int id) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.extras} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        unit TEXT DEFAULT ''
      )
    ''');
    final db = await dbHelper.database;
    return await db.delete(DbTables.extras, where: 'id = ?', whereArgs: [id]);
  }
}
