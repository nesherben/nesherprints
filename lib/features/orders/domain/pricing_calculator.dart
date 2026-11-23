import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Datos de una placa necesarios para el cálculo.
class PricingPlate {
  const PricingPlate({required this.materialId, required this.grams});

  final int? materialId;
  final double grams;
}

/// Resultado de la estimación de un pedido.
class PriceEstimate {
  const PriceEstimate({
    required this.materialCost,
    required this.paintCost,
    required this.extrasCost,
    required this.suggestedPrice,
  });

  static const zero = PriceEstimate(
    materialCost: 0,
    paintCost: 0,
    extrasCost: 0,
    suggestedPrice: 0,
  );

  /// Material de las placas + recargo por placa.
  final double materialCost;
  final double paintCost;
  final double extrasCost;

  /// (material + extras) × (1 + margen) + pintura.
  final double suggestedPrice;

  /// Coste de fabricación total.
  double get totalCost => materialCost + paintCost + extrasCost;
}

/// Semáforo del precio final frente al coste y al sugerido.
enum PriceHealth {
  /// Sin precio o sin coste: color neutro.
  neutral,

  /// Igual o por encima del sugerido.
  good,

  /// Entre el coste y el sugerido.
  low,

  /// Igual o por debajo del coste (pérdidas).
  loss;

  static PriceHealth evaluate({
    required double price,
    required PriceEstimate estimate,
  }) {
    final cost = estimate.totalCost;
    if (price <= 0 || cost <= 0) return neutral;
    if (price >= estimate.suggestedPrice) return good;
    if (price > cost) return low;
    return loss;
  }
}

/// Motor de precios del formulario de pedido.
class PricingCalculator {
  PricingCalculator._();

  /// Estima coste y precio sugerido.
  ///
  /// - [materialCostPerKg]: coste €/kg por id de material.
  /// - [extraUnitPrices]: precio unitario por id de pieza.
  /// - [selectedExtras]: cantidad por id de pieza.
  ///
  /// Recargo por placa (comportamiento actual, ver docs/SPEC.md): por cada
  /// placa con material conocido se acumula
  /// `plateExtraCost × (1 + (nPlacas − 1) × 0,1)` y el acumulado se suma al
  /// coste de esa placa, por lo que crece de forma cuadrática con el número
  /// de placas.
  static PriceEstimate estimate({
    required List<PricingPlate> plates,
    required Map<int, double> materialCostPerKg,
    required Map<int, double> extraUnitPrices,
    required Map<int, int> selectedExtras,
    required bool isPainted,
    required double paintHours,
    required PricingSettings settings,
  }) {
    var materialCost = 0.0;
    var accumulatedPlateExtra = 0.0;
    for (final plate in plates) {
      final costPerKg = materialCostPerKg[plate.materialId];
      if (plate.materialId == null || costPerKg == null) continue;
      accumulatedPlateExtra +=
          settings.plateExtraCost * (1 + (plates.length - 1) * 0.1);
      materialCost += (plate.grams / 1000) * costPerKg + accumulatedPlateExtra;
    }

    final paintCost = isPainted
        ? paintHours * settings.paintingCostPerHour
        : 0.0;

    var extrasCost = 0.0;
    for (final entry in selectedExtras.entries) {
      final unitPrice = extraUnitPrices[entry.key];
      if (unitPrice != null) extrasCost += unitPrice * entry.value;
    }

    return PriceEstimate(
      materialCost: materialCost,
      paintCost: paintCost,
      extrasCost: extrasCost,
      suggestedPrice:
          (materialCost + extrasCost) *
              (1 + settings.profitMarginPercent / 100) +
          paintCost,
    );
  }
}
