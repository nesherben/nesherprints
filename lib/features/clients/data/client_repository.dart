import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/features/clients/domain/client.dart';

class ClientRepository {
  ClientRepository(this._db);

  final AppDatabase _db;

  /// Todos los clientes, ordenados por nombre.
  Future<List<Client>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      ClientsTable.name,
      orderBy: '${ClientsTable.clientName} ASC',
    );
    return rows.map(Client.fromMap).toList();
  }

  /// Inserta o actualiza según tenga `id`. Devuelve el id del cliente.
  Future<int> save(Client client) async {
    final db = await _db.database;
    if (client.id == null) {
      return db.insert(ClientsTable.name, client.toMap());
    }
    await db.update(
      ClientsTable.name,
      client.toMap(),
      where: '${ClientsTable.id} = ?',
      whereArgs: [client.id],
    );
    return client.id!;
  }

  /// Borra el cliente. Sus pedidos se conservan, sin cliente asignado.
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        OrdersTable.name,
        {OrdersTable.clientId: null},
        where: '${OrdersTable.clientId} = ?',
        whereArgs: [id],
      );
      await txn.delete(
        ClientsTable.name,
        where: '${ClientsTable.id} = ?',
        whereArgs: [id],
      );
    });
  }
}
