import 'package:nesherprints/core/constants/app_constants.dart';
import 'package:nesherprints/features/orders/domain/paint_detail.dart';

/// Ajustes de la calculadora de precios (tabla `settings`).
class PricingSettings {
  const PricingSettings({
    this.profitMarginPercent = FinanceDefaults.profitMarginPercent,
    this.safetyMarginPercent = FinanceDefaults.safetyMarginPercent,
    this.paintingCostPerHour = FinanceDefaults.paintingCostPerHour,
    this.paintDetailFewCost = FinanceDefaults.paintDetailFewCost,
    this.paintDetailNormalCost = FinanceDefaults.paintDetailNormalCost,
    this.paintDetailManyCost = FinanceDefaults.paintDetailManyCost,
    this.kwhCost = FinanceDefaults.kwhCost,
    this.filamentPlateFee = FinanceDefaults.filamentPlateFee,
    this.resinPlateFee = FinanceDefaults.resinPlateFee,
    this.profitGoal = FinanceDefaults.profitGoal,
  });

  /// El precio recomendado se multiplica por `2 + profitMarginPercent / 100`.
  final double profitMarginPercent;

  /// Margen que se suma al coste real (material, luz y pintura).
  final double safetyMarginPercent;

  /// Coste de pintado por hora (€).
  final double paintingCostPerHour;

  /// Material de pintura (€) según el detalle: pocos (≤ 4 colores), normal
  /// (5–10) y muchos (> 10).
  final double paintDetailFewCost;
  final double paintDetailNormalCost;
  final double paintDetailManyCost;

  double paintDetailCost(PaintDetail detail) => switch (detail) {
    PaintDetail.few => paintDetailFewCost,
    PaintDetail.normal => paintDetailNormalCost,
    PaintDetail.many => paintDetailManyCost,
  };

  /// Coste de la luz por hora de impresión (€/h).
  final double kwhCost;

  /// Recargo base por placa extra según el material de la placa (€).
  final double filamentPlateFee;
  final double resinPlateFee;

  /// Objetivo de beneficio acumulado (€) que se compara en el panel.
  final double profitGoal;

  /// Desde el mapa clave → valor de `settings`; las claves que falten toman
  /// el valor por defecto.
  factory PricingSettings.fromMap(Map<String, double> v) => PricingSettings(
    profitMarginPercent:
        v[SettingKeys.profitMargin] ?? FinanceDefaults.profitMarginPercent,
    safetyMarginPercent:
        v[SettingKeys.safetyMargin] ?? FinanceDefaults.safetyMarginPercent,
    paintingCostPerHour:
        v[SettingKeys.paintingCostPerHour] ??
        FinanceDefaults.paintingCostPerHour,
    paintDetailFewCost:
        v[SettingKeys.paintDetailFewCost] ?? FinanceDefaults.paintDetailFewCost,
    paintDetailNormalCost:
        v[SettingKeys.paintDetailNormalCost] ??
        FinanceDefaults.paintDetailNormalCost,
    paintDetailManyCost:
        v[SettingKeys.paintDetailManyCost] ??
        FinanceDefaults.paintDetailManyCost,
    kwhCost: v[SettingKeys.kwhCost] ?? FinanceDefaults.kwhCost,
    filamentPlateFee:
        v[SettingKeys.filamentPlateFee] ?? FinanceDefaults.filamentPlateFee,
    resinPlateFee:
        v[SettingKeys.resinPlateFee] ?? FinanceDefaults.resinPlateFee,
    profitGoal: v[SettingKeys.profitGoal] ?? FinanceDefaults.profitGoal,
  );

  Map<String, double> toMap() => {
    SettingKeys.profitMargin: profitMarginPercent,
    SettingKeys.safetyMargin: safetyMarginPercent,
    SettingKeys.paintingCostPerHour: paintingCostPerHour,
    SettingKeys.paintDetailFewCost: paintDetailFewCost,
    SettingKeys.paintDetailNormalCost: paintDetailNormalCost,
    SettingKeys.paintDetailManyCost: paintDetailManyCost,
    SettingKeys.kwhCost: kwhCost,
    SettingKeys.filamentPlateFee: filamentPlateFee,
    SettingKeys.resinPlateFee: resinPlateFee,
    SettingKeys.profitGoal: profitGoal,
  };
}
