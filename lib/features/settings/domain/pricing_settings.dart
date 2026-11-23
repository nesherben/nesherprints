import 'package:nesherprints/core/constants/app_constants.dart';

/// Constantes de la calculadora de precios (tabla `settings`).
class PricingSettings {
  const PricingSettings({
    this.profitMarginPercent = FinanceDefaults.profitMarginPercent,
    this.paintingCostPerHour = FinanceDefaults.paintingCostPerHour,
    this.plateExtraCost = FinanceDefaults.plateExtraCost,
  });

  /// Margen de beneficio en % (45 = +45 %).
  final double profitMarginPercent;

  /// Coste de pintado por hora (€).
  final double paintingCostPerHour;

  /// Coste base añadido por cada placa (€). Ver `PricingCalculator`.
  final double plateExtraCost;

  /// Desde el mapa clave → valor de `settings`; las claves que falten toman
  /// el valor por defecto.
  factory PricingSettings.fromMap(
    Map<String, double> values,
  ) => PricingSettings(
    profitMarginPercent:
        values[SettingKeys.profitMargin] ?? FinanceDefaults.profitMarginPercent,
    paintingCostPerHour:
        values[SettingKeys.paintingCostPerHour] ??
        FinanceDefaults.paintingCostPerHour,
    plateExtraCost:
        values[SettingKeys.plateExtraCost] ?? FinanceDefaults.plateExtraCost,
  );

  Map<String, double> toMap() => {
    SettingKeys.profitMargin: profitMarginPercent,
    SettingKeys.paintingCostPerHour: paintingCostPerHour,
    SettingKeys.plateExtraCost: plateExtraCost,
  };
}
