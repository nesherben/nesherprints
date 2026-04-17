import '../database/db_helper.dart';

class ClientRepository {
  final dbHelper = DatabaseHelper.instance;

  // Crear cliente
  Future<int> insertClient(Map<String, dynamic> client) async {
    final db = await dbHelper.database;
    return await db.insert('clients', client);
  }

  // Obtener todos
  Future<List<Map<String, dynamic>>> getAllClients() async {
    final db = await dbHelper.database;
    return await db.query('clients', orderBy: 'name ASC');
  }

  // Actualizar
  Future<int> updateClient(Map<String, dynamic> client) async {
    final db = await dbHelper.database;
    return await db.update(
      'clients',
      client,
      where: 'id = ?',
      whereArgs: [client['id']],
    );
  }
}
