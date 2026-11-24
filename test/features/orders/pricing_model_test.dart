import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Con los ajustes por defecto: máquina = 0,25 kW × 0,15 €/kWh + 0,10 €/h =
/// 0,1375 €/h; 1 € por placa; pintura 10 €/h; margen 150 %; mínimo 5 €.
void main() {
  const settings = PricingSettings();

  PriceEstimate estimate({
    double grams = 100,
    int plateCount = 1,
    double hours = 8,
    double costPerKg = 20,
    double attempts = 1,
    bool isPainted = false,
    double paintHours = 0,
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
      isPainted: isPainted,
      paintHours: paintHours,
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
          isPainted: false,
          paintHours: 0,
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

    test(
      'los intentos multiplican material y máquina, no placas ni pintura',
      () {
        final e = estimate(attempts: 1.5, isPainted: true, paintHours: 1);
        expect(e.materialCost, closeTo(2 * 1.5, 1e-9));
        expect(e.machineCost, closeTo(1.1 * 1.5, 1e-9));
        expect(e.platesCost, 1);
        expect(e.paintCost, 10);
      },
    );

    test('la pintura son horas × tarifa, y solo si está marcada', () {
      expect(estimate(isPainted: true, paintHours: 2).paintCost, 20);
      expect(estimate(paintHours: 5).paintCost, 0);
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
        isPainted: false,
        paintHours: 0,
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

    test('las piezas y la pintura también llevan margen', () {
      final e = estimate(
        extras: {7: 4},
        isPainted: true,
        paintHours: 1,
      ); // 4,10 + 2 + 10
      expect(e.suggestedPrice, closeTo(16.1 * 2.5, 1e-9));
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

  group('PriceHealth', () {
    const est = PriceEstimate(
      materialCost: 10,
      machineCost: 0,
      platesCost: 0,
      paintCost: 0,
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
