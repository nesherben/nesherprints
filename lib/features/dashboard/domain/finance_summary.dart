import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_costing.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Etiqueta del mes de los pedidos que no tienen fecha.
const String kNoDateMonth = 'Sin fecha';

/// Totales de un mes (`YYYY-MM`).
class MonthStats {
  const MonthStats({
    this.orders = 0,
    this.gross = 0,
    this.cost = 0,
    this.paintCost = 0,
  });

  final int orders;
  final double gross;
  final double cost;

  /// Parte del coste que es pintura.
  final double paintCost;

  /// Beneficio real: facturado − coste.
  double get realProfit => gross - cost;

  /// Beneficio «teórico»: el real más la pintura (la pintura se cobra
  /// aparte, como en la columna `AB` del Excel).
  double get theoreticalProfit => realProfit + paintCost;

  /// Beneficio real sobre lo facturado (0–1; 0 si no se facturó nada).
  double get ratio => gross > 0 ? realProfit / gross : 0;

  MonthStats add({
    required double gross,
    required double cost,
    required double paintCost,
  }) => MonthStats(
    orders: orders + 1,
    gross: this.gross + gross,
    cost: this.cost + cost,
    paintCost: this.paintCost + paintCost,
  );
}

/// Pedido con importe pendiente de cobro.
class PendingOrder {
  const PendingOrder({
    required this.id,
    required this.name,
    required this.date,
    required this.amount,
  });

  final int id;
  final String name;
  final String date;
  final double amount;
}

/// Métricas del panel.
class FinanceSummary {
  const FinanceSummary({
    required this.completedOrders,
    required this.grossRevenue,
    required this.cost,
    required this.paintCost,
    required this.pendingCollection,
    required this.profitGoal,
    required this.monthly,
    required this.statusCounts,
    required this.pendingOrders,
    required this.wasteCost,
    required this.wasteGrams,
    required this.wasteRecords,
  });

  /// Pedidos que cuentan como ingreso (completados y enviados).
  final int completedOrders;

  /// Suma de precios de los pedidos completados o enviados.
  final double grossRevenue;

  /// Coste real de esos pedidos.
  final double cost;
  final double paintCost;

  /// Deuda pendiente de pedidos que no son borrador ni cancelados.
  final double pendingCollection;

  /// Objetivo de beneficio configurado.
  final double profitGoal;

  /// Totales por mes, ordenados cronológicamente.
  final Map<String, MonthStats> monthly;

  /// Número de pedidos por estado (todos los estados, en orden del enum).
  final Map<OrderStatus, int> statusCounts;

  /// Pedidos con deuda, de mayor a menor importe.
  final List<PendingOrder> pendingOrders;

  /// Material perdido en mermas (informativo: ya forma parte del coste de
  /// los pedidos a través de los intentos, así que no se resta aparte).
  final double wasteCost;
  final double wasteGrams;
  final int wasteRecords;

  double get realProfit => grossRevenue - cost;
  double get theoreticalProfit => realProfit + paintCost;

  /// Beneficio real sobre lo facturado (0–1).
  double get ratio => grossRevenue > 0 ? realProfit / grossRevenue : 0;

  /// Avance hacia el objetivo (beneficio teórico / objetivo; puede pasar de 1).
  double get goalProgress =>
      profitGoal > 0 ? theoreticalProfit / profitGoal : 0;

  int get totalOrders => statusCounts.values.fold(0, (a, b) => a + b);

  static FinanceSummary compute({
    required List<OrderSummary> orders,
    required Map<int, OrderCost> costs,
    required Map<int, double> materialCostPerKg,
    required List<WasteRecord> waste,
    required double profitGoal,
  }) {
    final counts = {for (final s in OrderStatus.values) s: 0};
    final monthly = <String, MonthStats>{};
    final pending = <PendingOrder>[];
    var completed = 0;
    var gross = 0.0, cost = 0.0, paint = 0.0, receivable = 0.0;

    for (final summary in orders) {
      final o = summary.order;
      counts[o.status] = counts[o.status]! + 1;

      if (o.status.countsAsReceivable && o.pendingAmount > 0) {
        receivable += o.pendingAmount;
        pending.add(
          PendingOrder(
            id: summary.id,
            name: o.name,
            date: o.date,
            amount: o.pendingAmount,
          ),
        );
      }

      if (o.status.countsAsRevenue) {
        final orderCost = costs[summary.id];
        final c = orderCost?.cost ?? 0;
        final p = orderCost?.paintCost ?? 0;
        completed++;
        gross += o.price;
        cost += c;
        paint += p;
        final month = o.date.length >= 7
            ? o.date.substring(0, 7)
            : kNoDateMonth;
        monthly[month] = (monthly[month] ?? const MonthStats()).add(
          gross: o.price,
          cost: c,
          paintCost: p,
        );
      }
    }

    var wasteCost = 0.0, wasteGrams = 0.0;
    for (final w in waste) {
      wasteGrams += w.grams;
      wasteCost += w.grams / 1000 * (materialCostPerKg[w.materialId] ?? 0);
    }

    final months = monthly.keys.toList()..sort();
    pending.sort((a, b) => b.amount.compareTo(a.amount));
    return FinanceSummary(
      completedOrders: completed,
      grossRevenue: gross,
      cost: cost,
      paintCost: paint,
      pendingCollection: receivable,
      profitGoal: profitGoal,
      monthly: {for (final m in months) m: monthly[m]!},
      statusCounts: counts,
      pendingOrders: pending,
      wasteCost: wasteCost,
      wasteGrams: wasteGrams,
      wasteRecords: waste.length,
    );
  }
}
