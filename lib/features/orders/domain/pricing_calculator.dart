import 'dart:math' as math;

import 'package:nesherprints/features/orders/domain/paint_detail.dart';
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
    required this.paintSurcharge,
    required this.extrasCost,
    required this.suggestedPrice,
    required this.minimumApplied,
  });

  static const zero = PriceEstimate(
    materialCost: 0,
    machineCost: 0,
    platesCost: 0,
    paintSurcharge: 0,
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

  /// Importe de la pintura que se suma al precio recomendado (no es coste: es
  /// trabajo tuyo). 0 si la pieza no se pinta.
  final double paintSurcharge;

  /// Piezas extra.
  final double extrasCost;

  /// Precio recomendado: `coste × (1 + margen)`, nunca menos que el mínimo,
  /// más el recargo de pintura.
  final double suggestedPrice;

  /// `true` si el recomendado es el precio mínimo (el cálculo salía menor).
  final bool minimumApplied;

  /// Coste real de fabricación: material, máquina, placas y piezas.
  double get cost => materialCost + machineCost + platesCost + extrasCost;
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
/// piezas   = Σ precio × cantidad
/// COSTE        = material + máquina + placas + piezas
/// SIN PINTAR   = max(mínimo, COSTE × (1 + margen/100))
/// RECOMENDADO  = SIN PINTAR + importe de pintura del nivel (si se pinta)
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
  /// - [paintDetail]: detalle de la pintura, o `null` si no se pinta. El
  ///   importe del nivel se suma al precio; no depende del peso.
  static PriceEstimate estimate({
    required List<PricingPlate> plates,
    required Map<int, double> materialCostPerKg,
    required Map<int, double> extraUnitPrices,
    required Map<int, int> selectedExtras,
    required double attempts,
    required PaintDetail? paintDetail,
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

    final materialCost = material * attempts;
    final machineCost =
        minutes / 60 * settings.machineCostPerPrintHour * attempts;
    final platesCost = plates.length * settings.plateCost;
    final printCost = materialCost + machineCost + platesCost;
    final cost = printCost + extras;

    if (cost <= 0) {
      return PriceEstimate(
        materialCost: materialCost,
        machineCost: machineCost,
        platesCost: platesCost,
        paintSurcharge: 0,
        extrasCost: extras,
        suggestedPrice: 0,
        minimumApplied: false,
      );
    }

    final withMargin = cost * (1 + settings.profitMarginPercent / 100);
    final unpainted = math.max(settings.minimumPrice, withMargin);
    final surcharge = paintDetail?.priceOf(settings) ?? 0;
    return PriceEstimate(
      materialCost: materialCost,
      machineCost: machineCost,
      platesCost: platesCost,
      paintSurcharge: surcharge,
      extrasCost: extras,
      suggestedPrice: unpainted + surcharge,
      minimumApplied: settings.minimumPrice > withMargin,
    );
  }
}
