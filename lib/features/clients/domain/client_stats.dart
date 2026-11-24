import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Estadísticas de un cliente calculadas a partir de sus pedidos.
class ClientStats {
  const ClientStats({this.orderCount = 0, this.billed = 0, this.pending = 0});

  /// Pedidos no cancelados.
  final int orderCount;

  /// Suma del precio de los pedidos que cuentan como ingreso.
  final double billed;

  /// Lo que debe: suma de lo pendiente (> 0) de los pedidos con deuda.
  final double pending;

  bool get owes => pending > 0;

  /// Estadísticas de cada cliente (por `clientId`). Los pedidos sin cliente
  /// se ignoran.
  static Map<int, ClientStats> fromOrders(List<OrderSummary> orders) {
    final counts = <int, int>{};
    final billed = <int, double>{};
    final pending = <int, double>{};
    for (final summary in orders) {
      final order = summary.order;
      final clientId = order.clientId;
      if (clientId == null) continue;
      if (order.status != OrderStatus.canceled) {
        counts[clientId] = (counts[clientId] ?? 0) + 1;
      }
      if (order.status.countsAsRevenue) {
        billed[clientId] = (billed[clientId] ?? 0) + order.price;
      }
      if (order.status.countsAsReceivable && order.pendingAmount > 0) {
        pending[clientId] = (pending[clientId] ?? 0) + order.pendingAmount;
      }
    }
    return {
      for (final id in {...counts.keys, ...billed.keys, ...pending.keys})
        id: ClientStats(
          orderCount: counts[id] ?? 0,
          billed: billed[id] ?? 0,
          pending: pending[id] ?? 0,
        ),
    };
  }
}
