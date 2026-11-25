import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Etiqueta del mes de los pedidos que no tienen fecha.
const String kNoDateMonth = 'Sin fecha';

/// Totales de un mes (`YYYY-MM`).
class MonthStats {
  const MonthStats({this.orders = 0, this.gross = 0, this.cost = 0});

  final int orders;
  final double gross;
  final double cost;

  /// Beneficio: facturado − coste.
  double get profit => gross - cost;

  /// Beneficio sobre lo facturado (0–1; 0 si no se facturó nada).
  double get ratio => gross > 0 ? profit / gross : 0;

  MonthStats add({required double gross, required double cost}) => MonthStats(
    orders: orders + 1,
    gross: this.gross + gross,
    cost: this.cost + cost,
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
    required this.pendingCollection,
    required this.profitGoal,
    required this.monthly,
    required this.statusCounts,
    required this.pendingOrders,
    required this.wasteCost,
    required this.wasteGrams,
    required this.wasteRecords,
    this.personalOrders = 0,
    this.personalCost = 0,
  });

  /// Pedidos que cuentan como ingreso (completados y enviados).
  final int completedOrders;

  /// Suma de precios de los pedidos completados o enviados.
  final double grossRevenue;

  /// Coste real de esos pedidos.
  final double cost;

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

  /// Pedidos para uso propio ya hechos y su coste de material (no cuentan
  /// como ingreso).
  final int personalOrders;
  final double personalCost;

  /// Beneficio: facturado − coste real.
  double get profit => grossRevenue - cost;

  /// Beneficio sobre lo facturado (0–1).
  double get ratio => grossRevenue > 0 ? profit / grossRevenue : 0;

  /// Avance hacia el objetivo (beneficio / objetivo; puede pasar de 1).
  double get goalProgress => profitGoal > 0 ? profit / profitGoal : 0;

  int get totalOrders => statusCounts.values.fold(0, (a, b) => a + b);

  /// [costs]: coste real por número de pedido (solo hace falta para los
  /// pedidos que cuentan como ingreso; si falta uno se toma 0).
  static FinanceSummary compute({
    required List<OrderSummary> orders,
    required Map<int, double> costs,
    required Map<int, double> materialCostPerKg,
    required List<WasteRecord> waste,
    required double profitGoal,
  }) {
    final counts = {for (final s in OrderStatus.values) s: 0};
    final monthly = <String, MonthStats>{};
    final pending = <PendingOrder>[];
    var completed = 0, personalOrders = 0;
    var personalCost = 0.0;
    var gross = 0.0, cost = 0.0, receivable = 0.0;

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

      if (o.isPersonal && o.status.countsAsRevenue) {
        personalOrders++;
        personalCost += costs[summary.id] ?? 0;
      } else if (o.countsAsRevenue) {
        final c = costs[summary.id] ?? 0;
        completed++;
        gross += o.price;
        cost += c;
        final month = o.date.length >= 7
            ? o.date.substring(0, 7)
            : kNoDateMonth;
        monthly[month] = (monthly[month] ?? const MonthStats()).add(
          gross: o.price,
          cost: c,
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
      pendingCollection: receivable,
      profitGoal: profitGoal,
      monthly: {for (final m in months) m: monthly[m]!},
      statusCounts: counts,
      pendingOrders: pending,
      wasteCost: wasteCost,
      wasteGrams: wasteGrams,
      wasteRecords: waste.length,
      personalOrders: personalOrders,
      personalCost: personalCost,
    );
  }
}
