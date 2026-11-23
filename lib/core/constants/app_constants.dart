/// Valores por defecto de la calculadora de precios.
class FinanceDefaults {
  FinanceDefaults._();

  static const double profitMarginPercent = 45.0;
  static const double paintingCostPerHour = 15.0;
  static const double plateExtraCost = 2.5;
}

/// Claves de la tabla `settings` (valores persistidos: no cambiar).
class SettingKeys {
  SettingKeys._();

  static const String profitMargin = 'margen_beneficio';
  static const String paintingCostPerHour = 'coste_hora_pintado';
  static const String plateExtraCost = 'coste_placa_extra';
}

class InventoryRules {
  InventoryRules._();

  /// Por debajo de este stock (g/ml) el material se marca como bajo.
  static const double lowStockGrams = 200;
}

class WasteRules {
  WasteRules._();

  /// Umbrales (%) de merma sobre el peso teórico del pedido.
  static const double mediumPercent = 10;
  static const double highPercent = 30;
}
