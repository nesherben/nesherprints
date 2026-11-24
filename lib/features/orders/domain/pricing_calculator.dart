import 'dart:math' as math;

import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Datos de una placa necesarios para el cálculo.
class PricingPlate {
  const PricingPlate({
    required this.materialId,
    required this.grams,
    required this.minutes,
  });

  final int? materialId;
  final double grams;
  final double minutes;
}

/// Resultado de la estimación de un pedido.
class PriceEstimate {
  const PriceEstimate({
    required this.materialCost,
    required this.machineCost,
    required this.platesCost,
    required this.paintCost,
    required this.extrasCost,
    required this.suggestedPrice,
    required this.minimumApplied,
  });

  static const zero = PriceEstimate(
    materialCost: 0,
    machineCost: 0,
    platesCost: 0,
    paintCost: 0,
    extrasCost: 0,
    suggestedPrice: 0,
    minimumApplied: false,
  );

  /// Material de las placas × intentos.
  final double materialCost;

  /// Máquina (electricidad y desgaste por hora de impresión) × intentos.
  final double machineCost;

  /// Preparación y retirada de las placas.
  final double platesCost;

  /// Pintura (horas × tarifa).
  final double paintCost;

  /// Piezas extra.
  final double extrasCost;

  /// Precio recomendado: `coste × (1 + margen)`, nunca menos que el mínimo.
  final double suggestedPrice;

  /// `true` si el recomendado es el precio mínimo (el cálculo salía menor).
  final bool minimumApplied;

  /// Coste real de fabricación: suma de todos los conceptos.
  double get cost =>
      materialCost + machineCost + platesCost + paintCost + extrasCost;
}

/// Semáforo del precio final frente al coste y al recomendado.
enum PriceHealth {
  /// Sin precio o sin coste: color neutro.
  neutral,

  /// Igual o por encima del recomendado.
  good,

  /// Entre el coste y el recomendado.
  low,

  /// Igual o por debajo del coste (pérdidas).
  loss;

  static PriceHealth evaluate({
    required double price,
    required PriceEstimate estimate,
  }) {
    if (price <= 0 || estimate.cost <= 0) return neutral;
    if (price >= estimate.suggestedPrice) return good;
    if (price > estimate.cost) return low;
    return loss;
  }
}

/// Motor de precios. Modelo (detalle en docs/SPEC.md §4.2):
///
/// ```
/// material = Σ gramos/1000 × €/kg × intentos
/// máquina  = horas × (kW × €/kWh + desgaste €/h) × intentos
/// placas   = nº de placas × coste por placa
/// pintura  = pintado ? horas de pintura × €/h : 0
/// piezas   = Σ precio × cantidad
/// COSTE        = material + máquina + placas + pintura + piezas
/// RECOMENDADO  = max(mínimo, COSTE × (1 + margen/100))
/// ```
class PricingCalculator {
  PricingCalculator._();

  /// Estima coste y precio recomendado.
  ///
  /// - [materialCostPerKg]: coste €/kg por id de material.
  /// - [extraUnitPrices]: precio unitario por id de pieza.
  /// - [selectedExtras]: cantidad por id de pieza.
  /// - [attempts]: 1 = a la primera; 1,3 = +30 % de material y máquina por
  ///   impresiones falladas.
  static PriceEstimate estimate({
    required List<PricingPlate> plates,
    required Map<int, double> materialCostPerKg,
    required Map<int, double> extraUnitPrices,
    required Map<int, int> selectedExtras,
    required double attempts,
    required bool isPainted,
    required double paintHours,
    required PricingSettings settings,
  }) {
    var material = 0.0;
    var minutes = 0.0;
    for (final plate in plates) {
      final costPerKg = materialCostPerKg[plate.materialId];
      if (costPerKg != null) material += plate.grams / 1000 * costPerKg;
      minutes += plate.minutes;
    }

    final extras = [
      for (final e in selectedExtras.entries)
        (extraUnitPrices[e.key] ?? 0) * e.value,
    ].fold(0.0, (a, b) => a + b);

    final costs = PriceEstimate(
      materialCost: material * attempts,
      machineCost: minutes / 60 * settings.machineCostPerPrintHour * attempts,
      platesCost: plates.length * settings.plateCost,
      paintCost: isPainted ? paintHours * settings.paintingCostPerHour : 0,
      extrasCost: extras,
      suggestedPrice: 0,
      minimumApplied: false,
    );

    final cost = costs.cost;
    if (cost <= 0) return costs;
    final withMargin = cost * (1 + settings.profitMarginPercent / 100);
    return PriceEstimate(
      materialCost: costs.materialCost,
      machineCost: costs.machineCost,
      platesCost: costs.platesCost,
      paintCost: costs.paintCost,
      extrasCost: costs.extrasCost,
      suggestedPrice: math.max(settings.minimumPrice, withMargin),
      minimumApplied: settings.minimumPrice > withMargin,
    );
  }
}
