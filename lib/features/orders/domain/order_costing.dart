import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Coste de un pedido ya guardado.
class OrderCost {
  const OrderCost({required this.cost, required this.paintCost});

  /// Coste real de fabricación (`Z` del Excel).
  final double cost;

  /// Parte del coste que es pintura (para el beneficio «teórico»).
  final double paintCost;
}

/// Calcula el coste de pedidos guardados con las fórmulas de la calculadora.
class OrderCosting {
  OrderCosting._();

  /// Coste real de [order].
  ///
  /// Si el pedido trae un coste fijo ([Order.costOverride], los importados
  /// del Excel) se usa tal cual y no se conoce la parte de pintura. En otro
  /// caso se recalcula con sus placas, piezas (a su precio registrado),
  /// intentos y pintura, y con los ajustes y precios de material **actuales**.
  static OrderCost of({
    required Order order,
    required List<OrderPlate> plates,
    required List<OrderExtraLine> extras,
    required Map<int, PricingMaterial> materials,
    required PricingSettings settings,
  }) {
    final fixed = order.costOverride;
    if (fixed != null) return OrderCost(cost: fixed, paintCost: 0);

    final estimate = PricingCalculator.estimate(
      plates: [
        for (final p in plates)
          PricingPlate(
            materialId: p.materialId,
            grams: p.grams,
            minutes: p.minutes,
          ),
      ],
      materials: materials,
      extraUnitPrices: {
        for (final line in extras) line.extraId: line.unitPrice ?? 0,
      },
      selectedExtras: {for (final line in extras) line.extraId: line.quantity},
      attempts: order.attempts,
      isPainted: order.isPainted,
      paintHours: order.paintHours,
      paintDetail: order.paintDetail,
      settings: settings,
    );
    return OrderCost(cost: estimate.cost, paintCost: estimate.paintCost);
  }
}
