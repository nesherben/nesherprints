import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Pedidos, sus placas, piezas extra y mermas.
///
/// Todas las operaciones que tocan stock (material o piezas) se ejecutan en
/// una transacción.
class OrderRepository {
  OrderRepository(this._db);

  final AppDatabase _db;

  // ==================== LECTURA ====================

  /// Todos los pedidos con agregados (coste material, gramos, merma, placas
  /// y nombre del cliente), del más reciente al más antiguo.
  Future<List<OrderSummary>> getAllWithDetails() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT
        o.*,
        c.${ClientsTable.clientName} AS client_name,
        (SELECT SUM((p.${OrderPlatesTable.grams} / 1000) * m.${MaterialsTable.costPerKg})
           FROM ${OrderPlatesTable.name} p
           JOIN ${MaterialsTable.name} m ON p.${OrderPlatesTable.materialId} = m.${MaterialsTable.id}
          WHERE p.${OrderPlatesTable.orderId} = o.${OrdersTable.id}) AS material_cost,
        (SELECT SUM(p.${OrderPlatesTable.grams})
           FROM ${OrderPlatesTable.name} p
          WHERE p.${OrderPlatesTable.orderId} = o.${OrdersTable.id}) AS total_theoretical_grams,
        (SELECT SUM(w.${OrderWasteTable.gramsWasted})
           FROM ${OrderWasteTable.name} w
          WHERE w.${OrderWasteTable.orderId} = o.${OrdersTable.id}) AS total_wasted_grams,
        (SELECT GROUP_CONCAT(p.${OrderPlatesTable.plateName}, ', ')
           FROM ${OrderPlatesTable.name} p
          WHERE p.${OrderPlatesTable.orderId} = o.${OrdersTable.id}) AS plates_names,
        (SELECT COUNT(*)
           FROM ${OrderPlatesTable.name} p
          WHERE p.${OrderPlatesTable.orderId} = o.${OrdersTable.id}) AS plates_count
      FROM ${OrdersTable.name} o
      LEFT JOIN ${ClientsTable.name} c ON c.${ClientsTable.id} = o.${OrdersTable.clientId}
      ORDER BY o.${OrdersTable.id} DESC
    ''');
    return rows.map(OrderSummary.fromMap).toList();
  }

  Future<List<OrderPlate>> getPlates(int orderId) async {
    final db = await _db.database;
    final rows = await db.query(
      OrderPlatesTable.name,
      where: '${OrderPlatesTable.orderId} = ?',
      whereArgs: [orderId],
    );
    return rows.map(OrderPlate.fromMap).toList();
  }

  Future<List<WasteRecord>> getAllWaste() async {
    final db = await _db.database;
    final rows = await db.query(OrderWasteTable.name);
    return rows.map(WasteRecord.fromMap).toList();
  }

  /// Consumos de la tabla heredada `order_items` (la app ya no la escribe).
  Future<List<LegacyOrderItem>> getLegacyItems() async {
    final db = await _db.database;
    final rows = await db.query(OrderItemsTable.name);
    return rows.map(LegacyOrderItem.fromMap).toList();
  }

  // ==================== ESCRITURA ====================

  /// Crea un pedido con sus placas y piezas extra (restando su stock).
  Future<int> create(
    Order order, {
    required List<OrderPlate> plates,
    List<OrderExtraLine> extras = const [],
  }) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final orderId = await txn.insert(OrdersTable.name, order.toMap());
      await _insertPlates(txn, orderId, plates);
      await _addExtras(txn, orderId, extras);
      return orderId;
    });
  }

  /// Actualiza los datos del pedido.
  ///
  /// - [plates] `null`: las placas no se tocan; si no, se reemplazan todas.
  /// - [extras] `null`: las piezas no se tocan; si no, se devuelven al stock
  ///   las anteriores y se aplican las nuevas.
  Future<void> update(
    Order order, {
    List<OrderPlate>? plates,
    List<OrderExtraLine>? extras,
  }) async {
    final orderId = order.id!;
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        OrdersTable.name,
        order.toMap(),
        where: '${OrdersTable.id} = ?',
        whereArgs: [orderId],
      );
      if (plates != null) {
        await txn.delete(
          OrderPlatesTable.name,
          where: '${OrderPlatesTable.orderId} = ?',
          whereArgs: [orderId],
        );
        await _insertPlates(txn, orderId, plates);
      }
      if (extras != null) {
        await _removeExtras(txn, orderId);
        await _addExtras(txn, orderId, extras);
      }
    });
  }

  /// Cambia solo el estado del pedido.
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    final db = await _db.database;
    await db.update(
      OrdersTable.name,
      {OrdersTable.status: status.dbValue},
      where: '${OrdersTable.id} = ?',
      whereArgs: [orderId],
    );
  }

  /// Completa el pedido: estado `Completed`, cobrado = precio y resta del
  /// inventario los gramos de todas sus placas.
  Future<void> complete(int orderId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE ${OrdersTable.name} '
        'SET ${OrdersTable.status} = ?, ${OrdersTable.paidAmount} = ${OrdersTable.price} '
        'WHERE ${OrdersTable.id} = ?',
        [OrderStatus.completed.dbValue, orderId],
      );
      final plates = await txn.query(
        OrderPlatesTable.name,
        where: '${OrderPlatesTable.orderId} = ?',
        whereArgs: [orderId],
      );
      for (final plate in plates.map(OrderPlate.fromMap)) {
        await _consumeMaterial(txn, plate.materialId!, plate.grams);
      }
    });
  }

  /// Borra el pedido devolviendo al stock sus piezas extra.
  ///
  /// Nota: no borra sus placas ni sus mermas (ver docs/SPEC.md).
  Future<void> delete(int orderId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await _removeExtras(txn, orderId);
      await txn.delete(
        OrderItemsTable.name,
        where: '${OrderItemsTable.orderId} = ?',
        whereArgs: [orderId],
      );
      await txn.delete(
        OrdersTable.name,
        where: '${OrdersTable.id} = ?',
        whereArgs: [orderId],
      );
    });
  }

  /// Registra una merma y resta los gramos del inventario.
  Future<void> addWaste({
    required int orderId,
    required int materialId,
    required double grams,
    required String reason,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(OrderWasteTable.name, {
        OrderWasteTable.orderId: orderId,
        OrderWasteTable.materialId: materialId,
        OrderWasteTable.gramsWasted: grams,
        OrderWasteTable.reason: reason,
      });
      await _consumeMaterial(txn, materialId, grams);
    });
  }

  // ==================== PRIVADOS ====================

  Future<void> _insertPlates(
    Transaction txn,
    int orderId,
    List<OrderPlate> plates,
  ) async {
    for (final plate in plates) {
      await txn.insert(OrderPlatesTable.name, plate.toMap(orderId));
    }
  }

  Future<void> _consumeMaterial(
    Transaction txn,
    int materialId,
    double grams,
  ) => txn.rawUpdate(
    'UPDATE ${MaterialsTable.name} '
    'SET ${MaterialsTable.stockGrams} = ${MaterialsTable.stockGrams} - ? '
    'WHERE ${MaterialsTable.id} = ?',
    [grams, materialId],
  );

  /// Vincula piezas al pedido con su precio unitario actual y resta stock.
  /// Las piezas que ya no existen se ignoran.
  Future<void> _addExtras(
    Transaction txn,
    int orderId,
    List<OrderExtraLine> extras,
  ) async {
    for (final line in extras) {
      final rows = await txn.query(
        ExtrasTable.name,
        columns: [ExtrasTable.price],
        where: '${ExtrasTable.id} = ?',
        whereArgs: [line.extraId],
      );
      if (rows.isEmpty) continue;
      await txn.insert(OrderExtrasTable.name, {
        OrderExtrasTable.orderId: orderId,
        OrderExtrasTable.extraId: line.extraId,
        OrderExtrasTable.quantity: line.quantity,
        OrderExtrasTable.unitPrice: (rows.first[ExtrasTable.price] as num)
            .toDouble(),
      });
      await _adjustExtraStock(txn, line.extraId, -line.quantity);
    }
  }

  /// Devuelve al stock las piezas del pedido y borra sus vínculos.
  Future<void> _removeExtras(Transaction txn, int orderId) async {
    final previous = await txn.query(
      OrderExtrasTable.name,
      columns: [OrderExtrasTable.extraId, OrderExtrasTable.quantity],
      where: '${OrderExtrasTable.orderId} = ?',
      whereArgs: [orderId],
    );
    await txn.delete(
      OrderExtrasTable.name,
      where: '${OrderExtrasTable.orderId} = ?',
      whereArgs: [orderId],
    );
    for (final row in previous) {
      await _adjustExtraStock(
        txn,
        row[OrderExtrasTable.extraId] as int,
        row[OrderExtrasTable.quantity] as int,
      );
    }
  }

  Future<void> _adjustExtraStock(
    Transaction txn,
    int extraId,
    int delta,
  ) async {
    if (delta == 0) return;
    await txn.rawUpdate(
      'UPDATE ${ExtrasTable.name} '
      'SET ${ExtrasTable.stock} = ${ExtrasTable.stock} + ? '
      'WHERE ${ExtrasTable.id} = ?',
      [delta, extraId],
    );
  }
}
