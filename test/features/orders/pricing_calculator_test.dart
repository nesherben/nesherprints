import 'package:flutter_test/flutter_test.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/paint_detail.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Casos reales de `Finanza.ods`. El coste (`Z`) es el valor de la hoja; el
/// precio recomendado (`F`) usa el multiplicador `2 + margen` (en la hoja,
/// `F` está roto: el 15 % no se aplica).
void main() {
  const settings = PricingSettings(); // valores del Excel

  PriceEstimate estimate({
    required double grams,
    required int plateCount,
    required double hours,
    required double costPerKg,
    MaterialKind kind = MaterialKind.filament,
    double attempts = 1,
    bool isPainted = false,
    double paintHours = 0,
    PaintDetail paintDetail = PaintDetail.normal,
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
      materials: {1: PricingMaterial(costPerKg: costPerKg, kind: kind)},
      extraUnitPrices: {7: 0.5},
      selectedExtras: extras,
      attempts: attempts,
      isPainted: isPainted,
      paintHours: paintHours,
      paintDetail: paintDetail,
      settings: s,
    );
  }

  group('Casos reales del Excel', () {
    test('fila 139 · p250 asiimov (1 placa, 7 h)', () {
      final e = estimate(grams: 166, plateCount: 1, hours: 7, costPerKg: 10);
      expect(e.cost, closeTo(2.210875, 1e-6));
      expect(e.suggestedPrice, closeTo(7.702375, 1e-6));
    });

    test('fila 142 · espadon (7 placas, 59 h)', () {
      final e = estimate(grams: 1640, plateCount: 7, hours: 59, costPerKg: 9);
      expect(e.cost, closeTo(25.038375, 1e-6));
      expect(e.suggestedPrice, closeTo(78.893283, 1e-5));
    });

    test('fila 143 · pennywise (resina, intentos 1,5)', () {
      final e = estimate(
        grams: 235,
        plateCount: 1,
        hours: 5,
        costPerKg: 11,
        kind: MaterialKind.resin,
        attempts: 1.5,
      );
      expect(e.cost, closeTo(4.7825625, 1e-6));
      expect(e.suggestedPrice, closeTo(11.518625, 1e-6));
    });

    test('fila 144 · armored (6 placas, 152 h: luz amortiguada y larga)', () {
      final e = estimate(
        grams: 2226,
        plateCount: 6,
        hours: 152,
        costPerKg: 11.5,
        attempts: 1.1,
      );
      expect(e.cost, closeTo(43.905735, 1e-6));
      expect(e.suggestedPrice, closeTo(142.040084, 1e-5));
    });

    test('fila 145 · nun gothic (6 placas, 155 h)', () {
      final e = estimate(
        grams: 2484,
        plateCount: 6,
        hours: 155,
        costPerKg: 11.5,
      );
      expect(e.cost, closeTo(43.847775, 1e-6));
      expect(e.suggestedPrice, closeTo(156.440254, 1e-5));
    });
  });

  group('Reglas', () {
    test('sin placas, piezas ni pintura todo es 0', () {
      expect(
        PricingCalculator.estimate(
          plates: const [],
          materials: const {},
          extraUnitPrices: const {},
          selectedExtras: const {},
          attempts: 1,
          isPainted: false,
          paintHours: 0,
          paintDetail: PaintDetail.normal,
          settings: settings,
        ).cost,
        0,
      );
    });

    test('la primera placa no paga recargo; las demás sí y crece un 10 %', () {
      expect(
        estimate(grams: 100, plateCount: 1, hours: 1, costPerKg: 10).plateFee,
        0,
      );
      // 3 placas filamento: (3−1) × 0,5 × (1 + 0,1 × 2) = 1,2
      expect(
        estimate(grams: 100, plateCount: 3, hours: 3, costPerKg: 10).plateFee,
        closeTo(1.2, 1e-9),
      );
      // Resina: tarifa 1,5 → (2−1) × 1,5 × 1,1 = 1,65
      expect(
        estimate(
          grams: 100,
          plateCount: 2,
          hours: 2,
          costPerKg: 10,
          kind: MaterialKind.resin,
        ).plateFee,
        closeTo(1.65, 1e-9),
      );
    });

    test('pintura: (horas × €/h + material según detalle) con margen', () {
      PriceEstimate painted(PaintDetail detail) => estimate(
        grams: 100,
        plateCount: 1,
        hours: 1,
        costPerKg: 10,
        isPainted: true,
        paintHours: 2,
        paintDetail: detail,
      );
      // Material por defecto: 3/90, 9/90 y 13/90 €.
      expect(
        painted(PaintDetail.few).paintCost,
        closeTo((16 + 3 / 90) * 1.15, 1e-9),
      );
      expect(
        painted(PaintDetail.normal).paintCost,
        closeTo((16 + 9 / 90) * 1.15, 1e-9),
      );
      expect(
        painted(PaintDetail.many).paintCost,
        closeTo((16 + 13 / 90) * 1.15, 1e-9),
      );
      expect(
        painted(PaintDetail.many).cost,
        greaterThan(painted(PaintDetail.few).cost),
      );
      expect(
        estimate(
          grams: 100,
          plateCount: 1,
          hours: 1,
          costPerKg: 10,
          paintHours: 5,
        ).paintCost,
        0,
        reason: 'sin marcar pintado no cuenta',
      );
    });

    test('piezas: suman al coste y al precio con el margen', () {
      final base = estimate(grams: 100, plateCount: 1, hours: 1, costPerKg: 10);
      final withExtras = estimate(
        grams: 100,
        plateCount: 1,
        hours: 1,
        costPerKg: 10,
        extras: {7: 4},
      );
      expect(withExtras.extrasCost, 2);
      expect(withExtras.cost - base.cost, closeTo(2, 1e-9));
      expect(
        withExtras.suggestedPrice - base.suggestedPrice,
        closeTo(2 * 1.15, 1e-9),
      );
    });

    test(
      'placas sin material conocido cuentan para n pero no suman material',
      () {
        final e = PricingCalculator.estimate(
          plates: const [
            PricingPlate(materialId: 1, grams: 100, minutes: 60),
            PricingPlate(materialId: null, grams: 500, minutes: 60),
          ],
          materials: const {
            1: PricingMaterial(costPerKg: 20, kind: MaterialKind.filament),
          },
          extraUnitPrices: const {},
          selectedExtras: const {},
          attempts: 1,
          isPainted: false,
          paintHours: 0,
          paintDetail: PaintDetail.normal,
          settings: settings,
        );
        expect(e.materialCost, closeTo(2, 1e-9));
        expect(e.plateFee, closeTo(0.5 * 1.1, 1e-9));
      },
    );

    test('el margen de beneficio cambia el multiplicador 2 + margen', () {
      const s = PricingSettings(profitMarginPercent: 30);
      final a = estimate(grams: 100, plateCount: 1, hours: 1, costPerKg: 10);
      final b = estimate(
        grams: 100,
        plateCount: 1,
        hours: 1,
        costPerKg: 10,
        s: s,
      );
      expect(b.suggestedPrice / a.suggestedPrice, closeTo(2.3 / 2.15, 1e-9));
    });
  });

  group('PriceHealth', () {
    const est = PriceEstimate(
      materialCost: 10,
      electricityCost: 0,
      plateFee: 0,
      paintCost: 0,
      extrasCost: 0,
      cost: 10,
      suggestedPrice: 14.5,
    );

    PriceHealth health(double price, [PriceEstimate e = est]) =>
        PriceHealth.evaluate(price: price, estimate: e);

    test('sin precio o sin coste es neutro', () {
      expect(health(0), PriceHealth.neutral);
      expect(health(20, PriceEstimate.zero), PriceHealth.neutral);
    });

    test('semáforo según coste y recomendado', () {
      expect(health(14.5), PriceHealth.good);
      expect(health(20), PriceHealth.good);
      expect(health(12), PriceHealth.low);
      expect(health(10), PriceHealth.loss);
      expect(health(5), PriceHealth.loss);
    });
  });
}
