import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_costing.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Congela el coste real de pedidos cerrados en `orders.cost_override`, para
/// que cambiar después un €/kg o un ajuste no altere el beneficio histórico
/// (SPEC §9, K1).
class CostFreezer {
  CostFreezer._();

  /// Congela el coste del pedido [orderId] si aún no tiene coste fijo.
  static Future<void> freeze(DatabaseExecutor db, int orderId) =>
      _freeze(db, '${OrdersTable.id} = ?', [orderId]);

  /// Congela todos los pedidos completados o enviados sin coste fijo
  /// (migración v7).
  static Future<void> freezeAllClosed(DatabaseExecutor db) => _freeze(
    db,
    '${OrdersTable.status} IN (?, ?)',
    const ['Completed', 'Shipped'],
  );

  /// Congela, sea cual sea su estado, los pedidos con placas de alguno de
  /// [materialIds] (antes de borrar esos materiales; migración v8).
  static Future<void> freezeUsingMaterials(
    DatabaseExecutor db,
    List<int> materialIds,
  ) {
    final marks = List.filled(materialIds.length, '?').join(', ');
    return _freeze(
      db,
      '${OrdersTable.id} IN (SELECT ${OrderPlatesTable.orderId} '
      'FROM ${OrderPlatesTable.name} '
      'WHERE ${OrderPlatesTable.materialId} IN ($marks))',
      materialIds,
    );
  }

  static Future<void> _freeze(
    DatabaseExecutor db,
    String where,
    List<Object?> args,
  ) async {
    final orders = await db.query(
      OrdersTable.name,
      where: '($where) AND ${OrdersTable.costOverride} IS NULL',
      whereArgs: args,
    );
    if (orders.isEmpty) return;

    final settings = PricingSettings.fromMap({
      for (final row in await db.query(SettingsTable.name))
        row[SettingsTable.key] as String: asDouble(row[SettingsTable.value]),
    });
    final costPerKg = {
      for (final row in await db.query(MaterialsTable.name))
        row[MaterialsTable.id] as int: asDouble(row[MaterialsTable.costPerKg]),
    };

    for (final row in orders) {
      final order = Order.fromMap(row);
      final plates = [
        for (final p in await db.query(
          OrderPlatesTable.name,
          where: '${OrderPlatesTable.orderId} = ?',
          whereArgs: [order.id],
        ))
          OrderPlate.fromMap(p),
      ];
      final extras = [
        for (final e in await db.query(
          OrderExtrasTable.name,
          where: '${OrderExtrasTable.orderId} = ?',
          whereArgs: [order.id],
        ))
          OrderExtraLine(
            extraId: e[OrderExtrasTable.extraId] as int,
            quantity: e[OrderExtrasTable.quantity] as int,
            unitPrice: asDouble(e[OrderExtrasTable.unitPrice]),
          ),
      ];
      final cost = OrderCosting.of(
        order: order,
        plates: plates,
        extras: extras,
        materialCostPerKg: costPerKg,
        settings: settings,
      );
      await db.update(
        OrdersTable.name,
        {OrdersTable.costOverride: cost},
        where: '${OrdersTable.id} = ?',
        whereArgs: [order.id],
      );
    }
  }
}
