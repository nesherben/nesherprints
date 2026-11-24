import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/orders/domain/paint_detail.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Con los ajustes por defecto: máquina = 0,25 kW × 0,15 €/kWh + 0,10 €/h =
/// 0,1375 €/h; 1 € por placa; margen 150 %; mínimo 5 €; pintura +20 / +60 / +100 €.
void main() {
  const settings = PricingSettings();

  PriceEstimate estimate({
    double grams = 100,
    int plateCount = 1,
    double hours = 8,
    double costPerKg = 20,
    double attempts = 1,
    PaintDetail? paint,
    Map<int, int> extras = const {},
    PricingSettings s = settings,
  }) {
    final plates = [
      for (var i = 0; i < plateCount; i++)
        PricingPlate(
          materialId: 1,
          grams: grams / plateCount,
          minutes: hours * 60 / plateCount,
        ),
    ];
    return PricingCalculator.estimate(
      plates: plates,
      materialCostPerKg: {1: costPerKg},
      extraUnitPrices: {7: 0.5},
      selectedExtras: extras,
      attempts: attempts,
      paintDetail: paint,
      settings: s,
    );
  }

  group('Coste', () {
    test(
      'sin placas, piezas ni pintura todo es 0 (y no hay precio mínimo)',
      () {
        final e = PricingCalculator.estimate(
          plates: const [],
          materialCostPerKg: const {},
          extraUnitPrices: const {},
          selectedExtras: const {},
          attempts: 1,
          paintDetail: null,
          settings: settings,
        );
        expect(e.cost, 0);
        expect(e.suggestedPrice, 0);
        expect(e.minimumApplied, isFalse);
      },
    );

    test('suma material, máquina y placas', () {
      // 100 g × 20 €/kg = 2 €; 8 h × 0,1375 = 1,10 €; 1 placa = 1 €
      final e = estimate();
      expect(e.materialCost, closeTo(2, 1e-9));
      expect(e.machineCost, closeTo(1.1, 1e-9));
      expect(e.platesCost, 1);
      expect(e.cost, closeTo(4.1, 1e-9));
    });

    test('cada placa cuesta lo mismo, también la primera', () {
      expect(estimate(plateCount: 3).platesCost, 3);
      expect(estimate(plateCount: 7).platesCost, 7);
    });

    test('los intentos multiplican material y máquina, no las placas', () {
      final e = estimate(attempts: 1.5);
      expect(e.materialCost, closeTo(2 * 1.5, 1e-9));
      expect(e.machineCost, closeTo(1.1 * 1.5, 1e-9));
      expect(e.platesCost, 1);
    });

    test('pintar no cambia el coste, solo el precio recomendado', () {
      expect(
        estimate(paint: PaintDetail.detailed).cost,
        closeTo(estimate().cost, 1e-9),
      );
    });

    test('las piezas suman a su precio', () {
      final base = estimate();
      final withExtras = estimate(extras: {7: 4});
      expect(withExtras.extrasCost, 2);
      expect(withExtras.cost - base.cost, closeTo(2, 1e-9));
    });

    test('un material desconocido no suma material pero la placa cuenta', () {
      final e = PricingCalculator.estimate(
        plates: const [
          PricingPlate(materialId: 99, grams: 500, minutes: 60),
          PricingPlate(materialId: null, grams: 500, minutes: 60),
        ],
        materialCostPerKg: const {1: 20},
        extraUnitPrices: const {},
        selectedExtras: const {},
        attempts: 1,
        paintDetail: null,
        settings: settings,
      );
      expect(e.materialCost, 0);
      expect(e.platesCost, 2);
    });
  });

  group('Precio recomendado', () {
    test('coste × (1 + margen)', () {
      final e = estimate(); // coste 4,10
      expect(e.suggestedPrice, closeTo(4.1 * 2.5, 1e-9));
      expect(e.minimumApplied, isFalse);
    });

    test('el margen es configurable', () {
      final e = estimate(s: const PricingSettings(profitMarginPercent: 100));
      expect(e.suggestedPrice, closeTo(4.1 * 2, 1e-9));
    });

    test('las piezas también llevan margen', () {
      final e = estimate(extras: {7: 4}); // 4,10 + 2
      expect(e.suggestedPrice, closeTo(6.1 * 2.5, 1e-9));
    });

    test('nunca baja del precio mínimo', () {
      // 10 g, 30 min: coste ≈ 1,27 € → 3,17 € con margen < 5 €
      final e = estimate(grams: 10, hours: 0.5);
      expect(e.suggestedPrice, 5);
      expect(e.minimumApplied, isTrue);

      final custom = estimate(
        grams: 10,
        hours: 0.5,
        s: const PricingSettings(minimumPrice: 8),
      );
      expect(custom.suggestedPrice, 8);
    });

    test('la electricidad y el desgaste se configuran por separado', () {
      const s = PricingSettings(kwhPrice: 0.40, machineCostPerHour: 0.20);
      expect(s.machineCostPerPrintHour, closeTo(0.25 * 0.40 + 0.20, 1e-12));
      final e = estimate(hours: 10, s: s);
      expect(e.machineCost, closeTo(10 * 0.30, 1e-9));
    });

    test('caso real: espadón, 7 placas y 59 h (cobrado 80 €)', () {
      final e = estimate(grams: 1640, plateCount: 7, hours: 59, costPerKg: 9);
      // material 14,76 + máquina 59 × 0,1375 + 7 placas = 29,8725
      expect(e.cost, closeTo(29.8725, 1e-9));
      expect(e.suggestedPrice, closeTo(74.68125, 1e-9));
    });
  });

  group('Pintura', () {
    test('suma el importe del nivel al precio sin pintar', () {
      final base = estimate().suggestedPrice; // 10,25
      expect(
        estimate(paint: PaintDetail.simple).suggestedPrice,
        closeTo(base + 20, 1e-9),
      );
      expect(
        estimate(paint: PaintDetail.normal).suggestedPrice,
        closeTo(base + 60, 1e-9),
      );
      expect(
        estimate(paint: PaintDetail.detailed).suggestedPrice,
        closeTo(base + 100, 1e-9),
      );
    });

    test('el recargo es el importe del nivel; sin pintar es 0', () {
      expect(estimate(paint: PaintDetail.normal).paintSurcharge, 60);
      expect(estimate().paintSurcharge, 0);
    });

    test('no depende del peso ni de las piezas extra', () {
      final light = estimate(grams: 50, paint: PaintDetail.normal);
      final heavy = estimate(grams: 500, paint: PaintDetail.normal);
      expect(light.paintSurcharge, heavy.paintSurcharge);
      final withExtras = estimate(extras: {7: 4}, paint: PaintDetail.normal);
      expect(withExtras.paintSurcharge, 60);
      expect(
        withExtras.suggestedPrice - estimate(extras: {7: 4}).suggestedPrice,
        closeTo(60, 1e-9),
      );
    });

    test('una pieza diminuta paga la pintura sobre el precio mínimo', () {
      final e = estimate(grams: 10, hours: 0.5, paint: PaintDetail.normal);
      expect(e.suggestedPrice, closeTo(5 + 60, 1e-9));
    });

    test('los importes se configuran', () {
      const s = PricingSettings(paintPriceNormal: 45);
      final e = estimate(paint: PaintDetail.normal, s: s);
      expect(e.suggestedPrice, closeTo(10.25 + 45, 1e-9));
    });
  });

  group('PriceHealth', () {
    const est = PriceEstimate(
      materialCost: 10,
      machineCost: 0,
      platesCost: 0,
      paintSurcharge: 0,
      extrasCost: 0,
      suggestedPrice: 25,
      minimumApplied: false,
    );

    PriceHealth health(double price, [PriceEstimate e = est]) =>
        PriceHealth.evaluate(price: price, estimate: e);

    test('sin precio o sin coste es neutro', () {
      expect(health(0), PriceHealth.neutral);
      expect(health(20, PriceEstimate.zero), PriceHealth.neutral);
    });

    test('semáforo según coste y recomendado', () {
      expect(health(25), PriceHealth.good);
      expect(health(40), PriceHealth.good);
      expect(health(15), PriceHealth.low);
      expect(health(10), PriceHealth.loss);
      expect(health(5), PriceHealth.loss);
    });
  });
}
