import 'package:nesherprints/core/constants.dart';
import 'package:nesherprints/data/database/db_helper.dart';

class ClientRepository {
  final dbHelper = DatabaseHelper.instance;

  // Crear cliente
  Future<int> insertClient(Map<String, dynamic> client) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.clients} (
        ${DbColumns.clientId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.clientName} TEXT NOT NULL,
        ${DbColumns.clientPhone} TEXT,
        ${DbColumns.clientEmail} TEXT,
        notes TEXT
      )
    ''');
    final db = await dbHelper.database;
    return await db.insert(DbTables.clients, client);
  }

  // Obtener todos
  Future<List<Map<String, dynamic>>> getAllClients() async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.clients} (
        ${DbColumns.clientId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.clientName} TEXT NOT NULL,
        ${DbColumns.clientPhone} TEXT,
        ${DbColumns.clientEmail} TEXT,
        notes TEXT
      )
    ''');
    final db = await dbHelper.database;
    return await db.query(
      DbTables.clients,
      orderBy: '${DbColumns.clientName} ASC',
    );
  }

  // Actualizar
  Future<int> updateClient(Map<String, dynamic> client) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.clients} (
        ${DbColumns.clientId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.clientName} TEXT NOT NULL,
        ${DbColumns.clientPhone} TEXT,
        ${DbColumns.clientEmail} TEXT,
        notes TEXT
      )
    ''');
    final db = await dbHelper.database;
    return await db.update(
      DbTables.clients,
      client,
      where: '${DbColumns.clientId} = ?',
      whereArgs: [client['id']],
    );
  }
}
