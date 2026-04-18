import '../../core/constants.dart';
import '../database/db_helper.dart';

class ClientRepository {
  final dbHelper = DatabaseHelper.instance;

  // Crear cliente
  Future<int> insertClient(Map<String, dynamic> client) async {
    final db = await dbHelper.database;
    return await db.insert(DbTables.clients, client);
  }

  // Obtener todos
  Future<List<Map<String, dynamic>>> getAllClients() async {
    final db = await dbHelper.database;
    return await db.query(
      DbTables.clients,
      orderBy: '${DbColumns.clientName} ASC',
    );
  }

  // Actualizar
  Future<int> updateClient(Map<String, dynamic> client) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.clients,
      client,
      where: '${DbColumns.clientId} = ?',
      whereArgs: [client['id']],
    );
  }
}
