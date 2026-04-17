import '../database/db_helper.dart';

class OrderRepository {
  // Instancia de nuestro ayudante de base de datos
  final dbHelper = DatabaseHelper.instance;

  // 1. CREAR (C)
  // Recibe un mapa de datos, lo inserta en la tabla 'orders' y devuelve el ID generado.
  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await dbHelper.database;
    return await db.insert('orders', order);
  }

  // 2. LEER (R)
  // Devuelve todos los pedidos de la base de datos como una lista de mapas.
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await dbHelper.database;
    // Seleccionamos todo de la tabla 'orders' y lo ordenamos por ID de forma descendente (los más nuevos primero)
    return await db.query('orders', orderBy: 'id DESC');
  }

  // 3. ACTUALIZAR (U)
  // Actualiza un pedido específico usando su ID.
  Future<int> updateOrder(Map<String, dynamic> order) async {
    final db = await dbHelper.database;
    int id = order['id'];
    return await db.update('orders', order, where: 'id = ?', whereArgs: [id]);
  }

  // 4. BORRAR (D)
  // Elimina un pedido usando su ID.
  Future<int> deleteOrder(int id) async {
    final db = await dbHelper.database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }
}
