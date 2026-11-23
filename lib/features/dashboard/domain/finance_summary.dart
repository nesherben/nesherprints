import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Totales de un mes (`YYYY-MM`).
class MonthlyFinance {
  const MonthlyFinance({this.gross = 0, this.cost = 0});

  final double gross;
  final double cost;

  double get net => gross - cost;

  MonthlyFinance add({required double gross, required double cost}) =>
      MonthlyFinance(gross: this.gross + gross, cost: this.cost + cost);
}

/// Métricas del panel.
class FinanceSummary {
  const FinanceSummary({
    required this.grossRevenue,
    required this.netProfit,
    required this.pendingCollection,
    required this.monthly,
    required this.statusCounts,
  });

  /// Suma de precios de pedidos completados o enviados.
  final double grossRevenue;

  /// Bruto − coste de material (tabla heredada `order_items`) − coste de
  /// todas las mermas registradas.
  final double netProfit;

  /// Deuda pendiente de pedidos que no son borrador ni cancelados.
  final double pendingCollection;

  /// Bruto/coste por mes, ordenado cronológicamente.
  final Map<String, MonthlyFinance> monthly;

  /// Número de pedidos por estado (todos los estados, en orden del enum).
  final Map<OrderStatus, int> statusCounts;

  int get totalOrders => statusCounts.values.fold(0, (a, b) => a + b);

  static FinanceSummary compute({
    required List<OrderSummary> orders,
    required Map<int, double> materialCostPerKg,
    required List<LegacyOrderItem> legacyItems,
    required List<WasteRecord> waste,
  }) {
    final counts = {for (final s in OrderStatus.values) s: 0};
    final monthly = <String, MonthlyFinance>{};
    var gross = 0.0, materialCost = 0.0, pending = 0.0;

    final itemsByOrder = <int, List<LegacyOrderItem>>{};
    for (final item in legacyItems) {
      itemsByOrder.putIfAbsent(item.orderId, () => []).add(item);
    }

    for (final summary in orders) {
      final o = summary.order;
      counts[o.status] = counts[o.status]! + 1;

      if (o.status.countsAsReceivable && o.pendingAmount > 0) {
        pending += o.pendingAmount;
      }

      if (o.status.countsAsRevenue) {
        var orderCost = 0.0;
        for (final item in itemsByOrder[o.id] ?? const <LegacyOrderItem>[]) {
          orderCost +=
              item.grams / 1000 * (materialCostPerKg[item.materialId] ?? 0);
        }
        gross += o.price;
        materialCost += orderCost;
        final month = o.date.length >= 7 ? o.date.substring(0, 7) : o.date;
        monthly[month] = (monthly[month] ?? const MonthlyFinance()).add(
          gross: o.price,
          cost: orderCost,
        );
      }
    }

    var wasteCost = 0.0;
    for (final w in waste) {
      wasteCost += w.grams / 1000 * (materialCostPerKg[w.materialId] ?? 0);
    }

    final sortedMonths = monthly.keys.toList()..sort();
    return FinanceSummary(
      grossRevenue: gross,
      netProfit: gross - materialCost - wasteCost,
      pendingCollection: pending,
      monthly: {for (final m in sortedMonths) m: monthly[m]!},
      statusCounts: counts,
    );
  }
}
