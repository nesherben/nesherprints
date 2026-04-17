import '../database/db_helper.dart';

class OrderRepository {
  final dbHelper = DatabaseHelper.instance;

  // CREAR: Guarda el pedido y sus materiales de golpe
  Future<int> insertOrder(
    Map<String, dynamic> order, {
    List<Map<String, dynamic>>? items,
  }) async {
    final db = await dbHelper.database;

    // Usamos una transacción: o se guarda todo, o no se guarda nada
    return await db.transaction((txn) async {
      int orderId = await txn.insert('orders', order);

      // Si hay materiales asociados (los filamentos o resina), los guardamos en la tabla puente
      if (items != null && items.isNotEmpty) {
        for (var item in items) {
          item['order_id'] = orderId;
          await txn.insert('order_items', item);
        }
      }
      return orderId;
    });
  }

  // LEER: Obtiene todos los pedidos
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await dbHelper.database;
    return await db.query('orders', orderBy: 'id DESC');
  }

  // ACTUALIZAR
  Future<int> updateOrder(
    Map<String, dynamic> order, {
    List<Map<String, dynamic>>? items,
  }) async {
    final db = await dbHelper.database;
    int orderId = order['id'];

    return await db.transaction((txn) async {
      // 1. Actualizamos los datos básicos del pedido
      await txn.update('orders', order, where: 'id = ?', whereArgs: [orderId]);

      // 2. Si nos pasan materiales nuevos, borramos los viejos y metemos los nuevos
      if (items != null) {
        await txn.delete(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );
        for (var item in items) {
          item['order_id'] = orderId;
          await txn.insert('order_items', item);
        }
      }
      return orderId;
    });
  }

  // BORRAR: Elimina el pedido y limpia la tabla puente
  Future<void> deleteOrder(int id) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [id],
      ); // Borrar hijos
      await txn.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
      ); // Borrar padre
    });
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await dbHelper.database;
    return await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // --- GESTIÓN DE COBROS ---
  Future<int> updatePayment(int orderId, double amount) async {
    final db = await dbHelper.database;
    return await db.update(
      'orders',
      {'paid_amount': amount},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // --- GESTIÓN DE MERMAS (FALLOS) ---
  Future<void> addWaste(
    int orderId,
    int materialId,
    double grams,
    String reason,
  ) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. Registramos el fallo
      await txn.insert('order_waste', {
        'order_id': orderId,
        'material_id': materialId,
        'grams_wasted': grams,
        'reason': reason,
      });
      // 2. IMPORTANTE: Restamos ese material del inventario general
      await txn.rawUpdate(
        'UPDATE materials SET stock_g = stock_g - ? WHERE id = ?',
        [grams, materialId],
      );
    });
  }

  // Para el Dashboard: Obtener todos los fallos
  Future<List<Map<String, dynamic>>> getAllWaste() async {
    final db = await dbHelper.database;
    return await db.query('order_waste');
  }
}
