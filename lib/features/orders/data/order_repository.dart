import 'dart:math' as math;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_rules.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Pedidos, sus placas, piezas extra y mermas.
///
/// Todas las operaciones que tocan stock (material o piezas) se ejecutan en
/// una transacción y respetan las reglas de estado (ver docs/SPEC.md §5):
/// - el material solo se descuenta al **completar**, una única vez;
/// - un pedido completado/enviado no se puede modificar ni reabrir;
/// - las piezas se descuentan al crear/editar y se devuelven al borrar.
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

  /// Piezas extra de un pedido, con el precio unitario registrado.
  Future<List<OrderExtraLine>> getExtras(int orderId) async {
    final db = await _db.database;
    final rows = await db.query(
      OrderExtrasTable.name,
      where: '${OrderExtrasTable.orderId} = ?',
      whereArgs: [orderId],
    );
    return [for (final row in rows) _lineFromRow(row)];
  }

  /// Placas de todos los pedidos, agrupadas por número de pedido.
  Future<Map<int, List<OrderPlate>>> getPlatesByOrder() async {
    final db = await _db.database;
    final rows = await db.query(OrderPlatesTable.name);
    final result = <int, List<OrderPlate>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row[OrderPlatesTable.orderId] as int, () => [])
          .add(OrderPlate.fromMap(row));
    }
    return result;
  }

  /// Piezas extra de todos los pedidos, agrupadas por número de pedido.
  Future<Map<int, List<OrderExtraLine>>> getExtraLinesByOrder() async {
    final db = await _db.database;
    final rows = await db.query(OrderExtrasTable.name);
    final result = <int, List<OrderExtraLine>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row[OrderExtrasTable.orderId] as int, () => [])
          .add(_lineFromRow(row));
    }
    return result;
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
  ///
  /// Lanza [OrderRuleException] si el pedido no es válido o ya viene cerrado.
  Future<int> create(
    Order order, {
    required List<OrderPlate> plates,
    List<OrderExtraLine> extras = const [],
  }) async {
    OrderRules.requireValid(order);
    if (order.status.isLocked) {
      throw const OrderRuleException(
        'Un pedido nuevo no puede nacer completado o enviado.',
      );
    }
    final db = await _db.database;
    return db.transaction((txn) async {
      final orderId = await txn.insert(OrdersTable.name, order.toMap());
      await _insertPlates(txn, orderId, plates);
      await _addExtras(txn, orderId, extras, const {});
      return orderId;
    });
  }

  /// Actualiza los datos del pedido.
  ///
  /// - [plates] `null`: las placas no se tocan; si no, se reemplazan todas
  ///   (una lista vacía las borra).
  /// - [extras] `null`: las piezas no se tocan; si no, se devuelven al stock
  ///   las anteriores y se aplican las nuevas. Una pieza que ya estaba en el
  ///   pedido conserva el precio unitario registrado.
  ///
  /// Lanza [OrderRuleException] si el pedido no es válido o está cerrado.
  Future<void> update(
    Order order, {
    List<OrderPlate>? plates,
    List<OrderExtraLine>? extras,
  }) async {
    final orderId = order.id!;
    OrderRules.requireValid(order);
    if (order.status.isLocked) {
      throw const OrderRuleException('Para cerrar un pedido usa "Completar".');
    }
    final db = await _db.database;
    await db.transaction((txn) async {
      final current = await _statusOf(txn, orderId);
      if (current.isLocked) {
        throw const OrderRuleException(
          'Un pedido completado o enviado no se puede modificar.',
        );
      }
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
        final previous = await _removeExtras(txn, orderId);
        await _addExtras(txn, orderId, extras, {
          for (final line in previous) line.extraId: line.unitPrice!,
        });
      }
    });
  }

  /// Cambio rápido de estado. Un pedido abierto puede pasar a cualquier
  /// estado abierto; uno `Completed` solo puede pasar a `Shipped`.
  /// `Completed` se alcanza únicamente con [complete].
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final current = await _statusOf(txn, orderId);
      if (current == status) return;
      if (!current.quickChangeTargets.contains(status)) {
        throw OrderRuleException(
          current.isLocked
              ? 'Un pedido ${current.label.toLowerCase()} no se puede reabrir.'
              : 'Para pasar a ${status.label.toLowerCase()} usa "Completar".',
        );
      }
      await txn.update(
        OrdersTable.name,
        {OrdersTable.status: status.dbValue},
        where: '${OrdersTable.id} = ?',
        whereArgs: [orderId],
      );
    });
  }

  /// Completa el pedido: estado `Completed`, cobrado = precio y resta del
  /// inventario el material de sus placas, descontando lo que ya salió como
  /// merma de ese mismo material. Completar un pedido ya cerrado no hace nada.
  Future<void> complete(int orderId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final current = await _statusOf(txn, orderId);
      if (current.isLocked) return;
      if (current == OrderStatus.canceled) {
        throw const OrderRuleException(
          'No se puede completar un pedido cancelado.',
        );
      }
      await txn.rawUpdate(
        'UPDATE ${OrdersTable.name} '
        'SET ${OrdersTable.status} = ?, ${OrdersTable.paidAmount} = ${OrdersTable.price} '
        'WHERE ${OrdersTable.id} = ?',
        [OrderStatus.completed.dbValue, orderId],
      );

      final planned = <int, double>{};
      for (final row in await txn.query(
        OrderPlatesTable.name,
        where: '${OrderPlatesTable.orderId} = ?',
        whereArgs: [orderId],
      )) {
        final plate = OrderPlate.fromMap(row);
        planned[plate.materialId!] =
            (planned[plate.materialId!] ?? 0) + plate.grams;
      }
      final wasted = <int, double>{
        for (final row in await txn.rawQuery(
          'SELECT ${OrderWasteTable.materialId} AS material, '
          'SUM(${OrderWasteTable.gramsWasted}) AS grams '
          'FROM ${OrderWasteTable.name} '
          'WHERE ${OrderWasteTable.orderId} = ? '
          'GROUP BY ${OrderWasteTable.materialId}',
          [orderId],
        ))
          row['material'] as int: (row['grams'] as num).toDouble(),
      };
      for (final entry in planned.entries) {
        final remaining = math.max(0.0, entry.value - (wasted[entry.key] ?? 0));
        if (remaining > 0) await _consumeMaterial(txn, entry.key, remaining);
      }
    });
  }

  /// Borra el pedido con sus placas, mermas y piezas, y devuelve al stock las
  /// piezas extra. El material **no** se repone: ya se gastó al imprimir.
  Future<void> delete(int orderId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await _removeExtras(txn, orderId);
      for (final table in [
        OrderItemsTable.name,
        OrderPlatesTable.name,
        OrderWasteTable.name,
      ]) {
        await txn.delete(table, where: 'order_id = ?', whereArgs: [orderId]);
      }
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
    if (grams.isNaN || grams.isInfinite || grams <= 0) {
      throw const OrderRuleException('Los gramos perdidos deben ser más de 0.');
    }
    final db = await _db.database;
    await db.transaction((txn) async {
      await _statusOf(txn, orderId); // comprueba que el pedido existe
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

  Future<OrderStatus> _statusOf(DatabaseExecutor txn, int orderId) async {
    final rows = await txn.query(
      OrdersTable.name,
      columns: [OrdersTable.status],
      where: '${OrdersTable.id} = ?',
      whereArgs: [orderId],
    );
    if (rows.isEmpty) throw const OrderRuleException('El pedido ya no existe.');
    return OrderStatus.fromDb(rows.first[OrdersTable.status] as String?);
  }

  static OrderExtraLine _lineFromRow(Map<String, Object?> row) =>
      OrderExtraLine(
        extraId: row[OrderExtrasTable.extraId] as int,
        quantity: row[OrderExtrasTable.quantity] as int,
        unitPrice: (row[OrderExtrasTable.unitPrice] as num).toDouble(),
      );

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

  /// Vincula piezas al pedido y resta stock. El precio unitario es el que ya
  /// tenía la pieza en el pedido ([keepPrices]) o, si es nueva, el actual.
  /// Las piezas que ya no existen se ignoran.
  Future<void> _addExtras(
    Transaction txn,
    int orderId,
    List<OrderExtraLine> extras,
    Map<int, double> keepPrices,
  ) async {
    for (final line in extras) {
      if (line.quantity <= 0) continue;
      final rows = await txn.query(
        ExtrasTable.name,
        columns: [ExtrasTable.price],
        where: '${ExtrasTable.id} = ?',
        whereArgs: [line.extraId],
      );
      if (rows.isEmpty) continue;
      final currentPrice = (rows.first[ExtrasTable.price] as num).toDouble();
      await txn.insert(OrderExtrasTable.name, {
        OrderExtrasTable.orderId: orderId,
        OrderExtrasTable.extraId: line.extraId,
        OrderExtrasTable.quantity: line.quantity,
        OrderExtrasTable.unitPrice:
            line.unitPrice ?? keepPrices[line.extraId] ?? currentPrice,
      });
      await _adjustExtraStock(txn, line.extraId, -line.quantity);
    }
  }

  /// Devuelve al stock las piezas del pedido y borra sus vínculos. Devuelve
  /// las líneas que había.
  Future<List<OrderExtraLine>> _removeExtras(
    Transaction txn,
    int orderId,
  ) async {
    final previous = await txn.query(
      OrderExtrasTable.name,
      where: '${OrderExtrasTable.orderId} = ?',
      whereArgs: [orderId],
    );
    await txn.delete(
      OrderExtrasTable.name,
      where: '${OrderExtrasTable.orderId} = ?',
      whereArgs: [orderId],
    );
    final lines = [for (final row in previous) _lineFromRow(row)];
    for (final line in lines) {
      await _adjustExtraStock(txn, line.extraId, line.quantity);
    }
    return lines;
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
