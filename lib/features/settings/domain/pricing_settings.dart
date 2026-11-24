import 'package:nesherprints/core/constants/app_constants.dart';

/// Ajustes de la calculadora de precios (tabla `settings`).
class PricingSettings {
  const PricingSettings({
    this.profitMarginPercent = FinanceDefaults.profitMarginPercent,
    this.kwhPrice = FinanceDefaults.kwhPrice,
    this.machineCostPerHour = FinanceDefaults.machineCostPerHour,
    this.plateCost = FinanceDefaults.plateCost,
    this.paintPriceSimple = FinanceDefaults.paintPriceSimple,
    this.paintPriceNormal = FinanceDefaults.paintPriceNormal,
    this.paintPriceDetailed = FinanceDefaults.paintPriceDetailed,
    this.minimumPrice = FinanceDefaults.minimumPrice,
    this.profitGoal = FinanceDefaults.profitGoal,
  });

  /// Margen sobre el coste: el precio recomendado es `coste × (1 + margen/100)`.
  final double profitMarginPercent;

  /// Precio de la electricidad (€/kWh).
  final double kwhPrice;

  /// Desgaste aproximado de la máquina (€/h de impresión).
  final double machineCostPerHour;

  /// Coste de preparar y retirar cada placa (€).
  final double plateCost;

  /// Pintura: factor sobre el precio sin pintar según el detalle.
  final double paintPriceSimple;
  final double paintPriceNormal;
  final double paintPriceDetailed;

  /// Precio recomendado mínimo de un pedido (€).
  final double minimumPrice;

  /// Objetivo de beneficio acumulado (€) que se compara en el panel.
  final double profitGoal;

  /// Coste de una hora de impresión: electricidad (potencia × €/kWh) más el
  /// desgaste de la máquina.
  double get machineCostPerPrintHour =>
      PricingConstants.printerKw * kwhPrice + machineCostPerHour;

  /// Desde el mapa clave → valor de `settings`; las claves que falten toman
  /// el valor por defecto.
  factory PricingSettings.fromMap(Map<String, double> v) => PricingSettings(
    profitMarginPercent:
        v[SettingKeys.profitMargin] ?? FinanceDefaults.profitMarginPercent,
    kwhPrice: v[SettingKeys.kwhPrice] ?? FinanceDefaults.kwhPrice,
    machineCostPerHour:
        v[SettingKeys.machineCostPerHour] ?? FinanceDefaults.machineCostPerHour,
    plateCost: v[SettingKeys.plateCost] ?? FinanceDefaults.plateCost,
    paintPriceSimple:
        v[SettingKeys.paintPriceSimple] ?? FinanceDefaults.paintPriceSimple,
    paintPriceNormal:
        v[SettingKeys.paintPriceNormal] ?? FinanceDefaults.paintPriceNormal,
    paintPriceDetailed:
        v[SettingKeys.paintPriceDetailed] ?? FinanceDefaults.paintPriceDetailed,
    minimumPrice: v[SettingKeys.minimumPrice] ?? FinanceDefaults.minimumPrice,
    profitGoal: v[SettingKeys.profitGoal] ?? FinanceDefaults.profitGoal,
  );

  Map<String, double> toMap() => {
    SettingKeys.profitMargin: profitMarginPercent,
    SettingKeys.kwhPrice: kwhPrice,
    SettingKeys.machineCostPerHour: machineCostPerHour,
    SettingKeys.plateCost: plateCost,
    SettingKeys.paintPriceSimple: paintPriceSimple,
    SettingKeys.paintPriceNormal: paintPriceNormal,
    SettingKeys.paintPriceDetailed: paintPriceDetailed,
    SettingKeys.minimumPrice: minimumPrice,
    SettingKeys.profitGoal: profitGoal,
  };
}
