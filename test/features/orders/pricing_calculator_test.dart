import 'package:flutter_test/flutter_test.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

void main() {
  const settings = PricingSettings(
    profitMarginPercent: 45,
    paintingCostPerHour: 15,
    plateExtraCost: 2.5,
  );

  PriceEstimate estimate({
    List<PricingPlate> plates = const [],
    Map<int, int> selectedExtras = const {},
    bool isPainted = false,
    double paintHours = 0,
  }) => PricingCalculator.estimate(
    plates: plates,
    materialCostPerKg: {1: 20},
    extraUnitPrices: {7: 0.5},
    selectedExtras: selectedExtras,
    isPainted: isPainted,
    paintHours: paintHours,
    settings: settings,
  );

  group('PricingCalculator', () {
    test('sin placas ni extras todo es 0', () {
      final e = estimate();
      expect(e.totalCost, 0);
      expect(e.suggestedPrice, 0);
    });

    test('una placa: material + recargo de placa', () {
      // 100 g a 20 €/kg = 2 €; recargo = 2,5 × (1 + 0 × 0,1) = 2,5
      final e = estimate(
        plates: [const PricingPlate(materialId: 1, grams: 100)],
      );
      expect(e.materialCost, closeTo(4.5, 1e-9));
      expect(e.suggestedPrice, closeTo(4.5 * 1.45, 1e-9));
    });

    test('pedido completo fija la fórmula actual (recargo acumulativo)', () {
      // n = 2 → recargo por paso 2,5 × 1,1 = 2,75
      // placa 1: 2 € + 2,75 (acumulado)  = 4,75
      // placa 2: 1 € + 5,50 (acumulado)  = 6,50  → material 11,25
      // extras: 4 × 0,5 = 2; pintura: 2 h × 15 = 30
      final e = estimate(
        plates: const [
          PricingPlate(materialId: 1, grams: 100),
          PricingPlate(materialId: 1, grams: 50),
        ],
        selectedExtras: {7: 4},
        isPainted: true,
        paintHours: 2,
      );
      expect(e.materialCost, closeTo(11.25, 1e-9));
      expect(e.extrasCost, closeTo(2, 1e-9));
      expect(e.paintCost, closeTo(30, 1e-9));
      expect(e.totalCost, closeTo(43.25, 1e-9));
      expect(e.suggestedPrice, closeTo(13.25 * 1.45 + 30, 1e-9));
    });

    test('placas sin material conocido no suman pero cuentan para n', () {
      final e = estimate(
        plates: const [
          PricingPlate(materialId: 1, grams: 100),
          PricingPlate(materialId: null, grams: 500),
          PricingPlate(materialId: 99, grams: 500),
        ],
      );
      // n = 3 → recargo 2,5 × 1,2 = 3; solo la primera placa suma.
      expect(e.materialCost, closeTo(2 + 3, 1e-9));
    });

    test('la pintura solo cuenta si está marcada', () {
      expect(estimate(paintHours: 3).paintCost, 0);
      expect(estimate(isPainted: true, paintHours: 3).paintCost, 45);
    });

    test('extras desconocidos se ignoran', () {
      expect(estimate(selectedExtras: {123: 5}).extrasCost, 0);
    });
  });

  group('PriceHealth', () {
    const est = PriceEstimate(
      materialCost: 10,
      paintCost: 0,
      extrasCost: 0,
      suggestedPrice: 14.5,
    );

    PriceHealth health(double price, [PriceEstimate e = est]) =>
        PriceHealth.evaluate(price: price, estimate: e);

    test('sin precio o sin coste es neutro', () {
      expect(health(0), PriceHealth.neutral);
      expect(health(20, PriceEstimate.zero), PriceHealth.neutral);
    });

    test('semáforo según coste y sugerido', () {
      expect(health(14.5), PriceHealth.good);
      expect(health(20), PriceHealth.good);
      expect(health(12), PriceHealth.low);
      expect(health(10), PriceHealth.loss);
      expect(health(5), PriceHealth.loss);
    });
  });
}
