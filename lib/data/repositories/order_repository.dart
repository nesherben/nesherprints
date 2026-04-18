import '../../core/constants.dart';
import '../database/db_helper.dart';

class OrderRepository {
  final dbHelper = DatabaseHelper.instance;

  Map<String, dynamic> _sanitizeOrderFields(Map<String, dynamic> order) {
    final allowedColumns = {
      DbColumns.orderClientId,
      DbColumns.orderName,
      DbColumns.orderPrice,
      DbColumns.orderPaidAmount,
      'date',
      DbColumns.orderStatus,
      DbColumns.orderIsPainted,
      'notes',
    };

    final sanitized = Map<String, dynamic>.from(order);
    sanitized.removeWhere(
      (key, _) => !allowedColumns.contains(key) && key != 'id',
    );
    return sanitized;
  }

  // CREAR: Guarda el pedido y sus materiales de golpe
  // --- GUARDAR PEDIDO CON SUS PLACAS ---
  Future<int> insertOrder(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> plates,
  ) async {
    final db = await dbHelper.database;
    final sanitizedOrder = _sanitizeOrderFields(orderData);
    return await db.transaction((txn) async {
      // 1. Insertar el pedido
      int orderId = await txn.insert(DbTables.orders, sanitizedOrder);

      // 2. Insertar cada placa vinculada
      for (var plate in plates) {
        plate[DbColumns.plateOrderId] = orderId;
        await txn.insert(DbTables.orderPlates, plate);
      }
      return orderId;
    });
  }

  Future<List<Map<String, dynamic>>> getOrderPlates(int orderId) async {
    final db = await dbHelper.database;
    return await db.query(
      DbTables.orderPlates,
      where: '${DbColumns.plateOrderId} = ?',
      whereArgs: [orderId],
    );
  }

  // --- REGISTRAR FALLO EN UNA PLACA ESPECÍFICA ---
  Future<void> registerPlateFailure(int plateId, String reason) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // 1. Buscamos los datos de la placa
      final plates = await txn.query(
        DbTables.orderPlates,
        where: '${DbColumns.plateId} = ?',
        whereArgs: [plateId],
      );
      if (plates.isEmpty) return;
      final plate = plates.first;

      // 2. Marcamos la placa como fallida
      await txn.update(
        DbTables.orderPlates,
        {DbColumns.plateStatus: 'Failed'},
        where: '${DbColumns.plateId} = ?',
        whereArgs: [plateId],
      );

      // 3. Insertamos en la tabla de mermas (waste) para que el Dashboard lo detecte
      await txn.insert(DbTables.orderWaste, {
        DbColumns.orderForeignId: plate['order_id'],
        DbColumns.materialForeignId: plate['material_id'],
        'grams_wasted': plate['grams'],
        'reason': 'Fallo en placa: ${plate['name']}. $reason',
      });

      // 4. Restamos el stock del inventario (porque el material se consumió igual)
      await txn.execute(
        'UPDATE ${DbTables.materials} SET stock_g = stock_g - ? WHERE ${DbColumns.materialId} = ?',
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
      -- Coste de material de las placas
      (SELECT SUM((p.${DbColumns.plateGrams} / 1000) * m.${DbColumns.materialCostPerKg}) 
       FROM ${DbTables.orderPlates} p 
       JOIN ${DbTables.materials} m ON p.${DbColumns.plateMaterialId} = m.${DbColumns.materialId} 
       WHERE p.${DbColumns.plateOrderId} = o.${DbColumns.orderId}) as material_cost,
      
      -- Gramos totales teóricos
      (SELECT SUM(p.${DbColumns.plateGrams}) FROM ${DbTables.orderPlates} p WHERE p.${DbColumns.plateOrderId} = o.${DbColumns.orderId}) as total_theoretical_grams,
      
      -- Gramos reales perdidos (CORREGIDO: Usamos orderForeignId)
      (SELECT SUM(w.grams_wasted) FROM ${DbTables.orderWaste} w WHERE w.${DbColumns.orderForeignId} = o.${DbColumns.orderId}) as total_wasted_grams,

      (SELECT GROUP_CONCAT(p.${DbColumns.plateName}, ', ') FROM ${DbTables.orderPlates} p WHERE p.${DbColumns.plateOrderId} = o.${DbColumns.orderId}) as plates_names,
      (SELECT COUNT(*) FROM ${DbTables.orderPlates} WHERE ${DbColumns.plateOrderId} = o.${DbColumns.orderId}) as plates_count
    FROM ${DbTables.orders} o
    ORDER BY o.${DbColumns.orderId} DESC
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
    final sanitizedOrder = _sanitizeOrderFields(order)..remove('id');

    return await db.transaction((txn) async {
      // 1. Actualizamos los datos básicos del pedido (estado, precio, etc.)
      await txn.update(
        DbTables.orders,
        sanitizedOrder,
        where: '${DbColumns.orderId} = ?',
        whereArgs: [orderId],
      );

      // 2. Si nos pasan placas nuevas/modificadas, resincronizamos la tabla
      if (plates != null) {
        // Borramos las placas anteriores de este pedido
        await txn.delete(
          DbTables.orderPlates,
          where: '${DbColumns.plateOrderId} = ?',
          whereArgs: [orderId],
        );

        // Insertamos la nueva lista de placas
        for (var plate in plates) {
          plate[DbColumns.plateOrderId] = orderId;
          // Nos aseguramos de que no pierda su estado por defecto
          plate.putIfAbsent(DbColumns.plateStatus, () => OrderStatus.pending);
          await txn.insert(DbTables.orderPlates, plate);
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
        DbTables.orderItems,
        where: '${DbColumns.orderForeignId} = ?',
        whereArgs: [id],
      ); // Borrar hijos
      await txn.delete(
        DbTables.orders,
        where: '${DbColumns.orderId} = ?',
        whereArgs: [id],
      ); // Borrar padre
    });
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await dbHelper.database;
    return await db.query(
      DbTables.orderItems,
      where: '${DbColumns.orderForeignId} = ?',
      whereArgs: [orderId],
    );
  }

  // --- GESTIÓN DE COBROS ---
  Future<int> updatePayment(int orderId, double amount) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.orders,
      {DbColumns.orderPaidAmount: amount},
      where: '${DbColumns.orderId} = ?',
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

      await txn.insert(DbTables.orderWaste, {
        DbColumns.orderForeignId: orderId,
        DbColumns.materialForeignId: materialId,
        'grams_wasted': grams,
        'reason': reason,
        // Si el error dice que no existe 'date', prueba a comentar esta línea
        // para que use el DEFAULT de la base de datos:
        // 'date': DateTime.now().toIso8601String(),
      });

      // 2. Restamos el material del inventario
      await txn.rawUpdate(
        'UPDATE ${DbTables.materials} SET stock_g = stock_g - ? WHERE ${DbColumns.materialId} = ?',
        [grams, materialId],
      );
    });
  }

  // Para el Dashboard: Obtener todos los fallos
  Future<List<Map<String, dynamic>>> getAllWaste() async {
    final db = await dbHelper.database;
    return await db.query(DbTables.orderWaste);
  }
}
