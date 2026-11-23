import 'dart:math' as math;

import 'package:nesherprints/features/inventory/domain/print_material.dart';
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

/// Datos de un material necesarios para el cálculo.
class PricingMaterial {
  const PricingMaterial({required this.costPerKg, required this.kind});

  final double costPerKg;
  final MaterialKind kind;
}

/// Resultado de la estimación de un pedido.
class PriceEstimate {
  const PriceEstimate({
    required this.materialCost,
    required this.electricityCost,
    required this.plateFee,
    required this.paintCost,
    required this.extrasCost,
    required this.cost,
    required this.suggestedPrice,
  });

  static const zero = PriceEstimate(
    materialCost: 0,
    electricityCost: 0,
    plateFee: 0,
    paintCost: 0,
    extrasCost: 0,
    cost: 0,
    suggestedPrice: 0,
  );

  /// Material de las placas (a la primera, sin multiplicar por intentos).
  final double materialCost;

  /// Luz de toda la impresión (lineal, a la primera).
  final double electricityCost;

  /// Recargo por placas extra.
  final double plateFee;

  /// Pintura, con el margen de seguridad.
  final double paintCost;
  final double extrasCost;

  /// Coste real de fabricación (`Z` en el Excel): material y luz × intentos,
  /// más recargo de placas, con margen de seguridad, más pintura y piezas.
  final double cost;

  /// Precio recomendado (`F` en el Excel).
  final double suggestedPrice;
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

/// Motor de precios. Transcribe las fórmulas de `Finanza.ods`
/// (ver docs/EXCEL_FORMULAS.md).
class PricingCalculator {
  PricingCalculator._();

  /// Horas por placa a partir de las cuales la luz se amortigua.
  static const double lightDampingHours = 12;
  static const double lightDampingFactor = 15;

  /// Horas por placa a partir de las cuales el precio sube por impresión larga.
  static const double longPrintHours = 8;
  static const double longPrintFactor = 0.085;

  /// Cada placa extra encarece el recargo un 10 %.
  static const double plateFeeGrowth = 0.1;

  /// Estima coste real y precio recomendado.
  ///
  /// - [materials]: coste €/kg y tipo por id de material.
  /// - [extraUnitPrices]: precio unitario por id de pieza.
  /// - [selectedExtras]: cantidad por id de pieza.
  /// - [attempts]: 1 = a la primera; 1,3 = +30 % de material y luz por fallos.
  ///
  /// Con varios materiales, el recargo por placa usa la media de las tarifas
  /// de las placas (el Excel solo admite un tipo por pedido).
  static PriceEstimate estimate({
    required List<PricingPlate> plates,
    required Map<int, PricingMaterial> materials,
    required Map<int, double> extraUnitPrices,
    required Map<int, int> selectedExtras,
    required double attempts,
    required bool isPainted,
    required double paintHours,
    required PaintDetail paintDetail,
    required PricingSettings settings,
  }) {
    if (plates.isEmpty && selectedExtras.isEmpty && !isPainted) {
      return PriceEstimate.zero;
    }

    final count = plates.length;
    var materialCost = 0.0;
    var totalMinutes = 0.0;
    var feeSum = 0.0;
    for (final plate in plates) {
      final material = materials[plate.materialId];
      if (material != null) {
        materialCost += plate.grams / 1000 * material.costPerKg;
      }
      totalMinutes += plate.minutes;
      feeSum += material?.kind == MaterialKind.resin
          ? settings.resinPlateFee
          : settings.filamentPlateFee;
    }
    final hours = totalMinutes / 60;
    final hoursPerPlate = count == 0 ? 0.0 : hours / count;

    final averageFee = count == 0 ? 0.0 : feeSum / count;
    final plateFee = math.max(
      0.0,
      (count - 1) * averageFee * (1 + plateFeeGrowth * (count - 1)),
    );

    final safety = 1 + settings.safetyMarginPercent / 100;
    final paintCost = isPainted
        ? (paintHours * settings.paintingCostPerHour +
                  settings.paintDetailCost(paintDetail)) *
              safety
        : 0.0;
    final extrasCost = [
      for (final e in selectedExtras.entries)
        (extraUnitPrices[e.key] ?? 0) * e.value,
    ].fold(0.0, (a, b) => a + b);

    // Coste real (Z): luz lineal y material, ambos × intentos.
    final electricityCost = hours * settings.kwhCost;
    final cost =
        math.max(
          0.0,
          (materialCost * attempts + electricityCost * attempts + plateFee) *
                  safety +
              paintCost,
        ) +
        extrasCost;

    // Precio recomendado (F): material ×2, luz amortigurada, recargo de
    // impresión larga y multiplicador 2 + margen.
    final dampedHours = hoursPerPlate <= lightDampingHours
        ? hoursPerPlate
        : lightDampingHours +
              lightDampingFactor * math.log(hoursPerPlate / lightDampingHours);
    final longPrint = hoursPerPlate <= longPrintHours
        ? 1.0
        : 1 + longPrintFactor * math.log(hoursPerPlate / longPrintHours);
    final base =
        (materialCost * 2 + count * dampedHours * settings.kwhCost + plateFee) *
        longPrint;
    final profit = settings.profitMarginPercent / 100;
    final suggestedPrice =
        base * (2 + profit) + paintCost + extrasCost * (1 + profit);

    return PriceEstimate(
      materialCost: materialCost,
      electricityCost: electricityCost,
      plateFee: plateFee,
      paintCost: paintCost,
      extrasCost: extrasCost,
      cost: cost,
      suggestedPrice: suggestedPrice,
    );
  }
}
