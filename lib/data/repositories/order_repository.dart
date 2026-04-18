import '../database/db_helper.dart';

class OrderRepository {
  final dbHelper = DatabaseHelper.instance;

  // CREAR: Guarda el pedido y sus materiales de golpe
  // --- GUARDAR PEDIDO CON SUS PLACAS ---
  Future<int> insertOrder(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> plates,
  ) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Insertar el pedido
      int orderId = await txn.insert('orders', orderData);

      // 2. Insertar cada placa vinculada
      for (var plate in plates) {
        plate['order_id'] = orderId;
        await txn.insert('order_plates', plate);
      }
      return orderId;
    });
  }

  Future<List<Map<String, dynamic>>> getOrderPlates(int orderId) async {
    final db = await dbHelper.database;
    return await db.query(
      'order_plates',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // --- REGISTRAR FALLO EN UNA PLACA ESPECÍFICA ---
  Future<void> registerPlateFailure(int plateId, String reason) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. Buscamos los datos de la placa
      final plates = await txn.query(
        'order_plates',
        where: 'id = ?',
        whereArgs: [plateId],
      );
      if (plates.isEmpty) return;
      final plate = plates.first;

      // 2. Marcamos la placa como fallida
      await txn.update(
        'order_plates',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [plateId],
      );

      // 3. Insertamos en la tabla de mermas (waste) para que el Dashboard lo detecte
      await txn.insert('order_waste', {
        'order_id': plate['order_id'],
        'material_id': plate['material_id'],
        'grams_wasted': plate['grams'],
        'reason': 'Fallo en placa: ${plate['name']}. $reason',
      });

      // 4. Restamos el stock del inventario (porque el material se consumió igual)
      await txn.execute(
        'UPDATE materials SET stock_g = stock_g - ? WHERE id = ?',
        [plate['grams'], plate['material_id']],
      );
    });
  }

  // LEER: Obtiene todos los pedidos
  Future<List<Map<String, dynamic>>> getAllOrdersWithDetails() async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
    SELECT 
      o.*,
      -- Coste de material de las placas (lo que debería haber gastado)
      (SELECT SUM((p.grams / 1000) * m.cost_per_kg) 
       FROM order_plates p 
       JOIN materials m ON p.material_id = m.id 
       WHERE p.order_id = o.id) as material_cost,
      
      -- Gramos totales teóricos (para el cálculo de tasa de fallo)
      (SELECT SUM(p.grams) FROM order_plates p WHERE p.order_id = o.id) as total_theoretical_grams,
      
      -- Gramos reales perdidos en mermas
      (SELECT SUM(w.grams_wasted) FROM order_waste w WHERE w.order_id = o.id) as total_wasted_grams,

      (SELECT GROUP_CONCAT(p.name, ', ') FROM order_plates p WHERE p.order_id = o.id) as plates_names,
      (SELECT COUNT(*) FROM order_plates WHERE order_id = o.id) as plates_count
    FROM orders o
    ORDER BY o.id DESC
  ''');

    return results;
  }

  // --- ACTUALIZAR PEDIDO CON SUS PLACAS ---
  Future<int> updateOrder(
    Map<String, dynamic> order, [
    List<Map<String, dynamic>>? plates,
  ]) async {
    final db = await dbHelper.database;
    int orderId = order['id'];

    return await db.transaction((txn) async {
      // 1. Actualizamos los datos básicos del pedido (estado, precio, etc.)
      await txn.update('orders', order, where: 'id = ?', whereArgs: [orderId]);

      // 2. Si nos pasan placas nuevas/modificadas, resincronizamos la tabla
      if (plates != null) {
        // Borramos las placas anteriores de este pedido
        await txn.delete(
          'order_plates',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        // Insertamos la nueva lista de placas
        for (var plate in plates) {
          plate['order_id'] = orderId;
          // Nos aseguramos de que no pierda su estado por defecto
          plate.putIfAbsent('status', () => 'Pending');
          await txn.insert('order_plates', plate);
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
  Future<void> addWaste({
    required int orderId,
    required int materialId,
    required double grams,
    required String reason,
  }) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      // 1. Registramos en la tabla de mermas
      // Quitamos 'date' de aquí porque en la tabla se llama 'date'
      // pero parece que hubo un lío en la creación.
      // Si la columna en tu CREATE TABLE era 'date', asegúrate de que existe.

      await txn.insert('order_waste', {
        'order_id': orderId,
        'material_id': materialId,
        'grams_wasted': grams,
        'reason': reason,
        // Si el error dice que no existe 'date', prueba a comentar esta línea
        // para que use el DEFAULT de la base de datos:
        // 'date': DateTime.now().toIso8601String(),
      });

      // 2. Restamos el material del inventario
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
