import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Calcula el coste real de pedidos ya guardados con la calculadora.
class OrderCosting {
  OrderCosting._();

  /// Coste real de [order].
  ///
  /// Si el pedido trae un coste fijo ([Order.costOverride], los importados)
  /// se usa tal cual. En otro caso se recalcula con sus placas, piezas (a su
  /// precio registrado), intentos y pintura, y con los ajustes y precios de
  /// material **actuales**.
  static double of({
    required Order order,
    required List<OrderPlate> plates,
    required List<OrderExtraLine> extras,
    required Map<int, double> materialCostPerKg,
    required PricingSettings settings,
  }) {
    final fixed = order.costOverride;
    if (fixed != null) return fixed;

    return PricingCalculator.estimate(
      plates: [
        for (final p in plates)
          PricingPlate(
            materialId: p.materialId,
            grams: p.grams,
            minutes: p.minutes,
          ),
      ],
      materialCostPerKg: materialCostPerKg,
      extraUnitPrices: {
        for (final line in extras) line.extraId: line.unitPrice ?? 0,
      },
      selectedExtras: {for (final line in extras) line.extraId: line.quantity},
      attempts: order.attempts,
      isPainted: order.isPainted,
      paintHours: order.paintHours,
      settings: settings,
    ).cost;
  }
}
