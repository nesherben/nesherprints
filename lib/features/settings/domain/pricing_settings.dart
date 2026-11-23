import 'package:nesherprints/core/constants/app_constants.dart';

/// Ajustes de la calculadora de precios (tabla `settings`).
class PricingSettings {
  const PricingSettings({
    this.profitMarginPercent = FinanceDefaults.profitMarginPercent,
    this.safetyMarginPercent = FinanceDefaults.safetyMarginPercent,
    this.paintingCostPerHour = FinanceDefaults.paintingCostPerHour,
    this.paintColorUnitCost = FinanceDefaults.paintColorUnitCost,
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

  /// Coste de cada unidad de color de pintura (€).
  final double paintColorUnitCost;

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
    paintColorUnitCost:
        v[SettingKeys.paintColorUnitCost] ?? FinanceDefaults.paintColorUnitCost,
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
    SettingKeys.paintColorUnitCost: paintColorUnitCost,
    SettingKeys.kwhCost: kwhCost,
    SettingKeys.filamentPlateFee: filamentPlateFee,
    SettingKeys.resinPlateFee: resinPlateFee,
    SettingKeys.profitGoal: profitGoal,
  };
}
