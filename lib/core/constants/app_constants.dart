/// Valores por defecto de la calculadora de precios (los del Excel `Finanza.ods`,
/// ver docs/EXCEL_FORMULAS.md).
class FinanceDefaults {
  FinanceDefaults._();

  /// Margen sobre el precio recomendado: el multiplicador es `2 + margen/100`.
  static const double profitMarginPercent = 15.0;

  /// Margen de seguridad sobre el coste real (material, luz y pintura).
  static const double safetyMarginPercent = 15.0;

  static const double paintingCostPerHour = 8.0;

  /// Coste de cada unidad de color de pintura (1/90 €).
  static const double paintColorUnitCost = 1 / 90;

  /// Coste de la luz por hora de impresión: 0,25 kW × 0,15 €/kWh.
  static const double kwhCost = 0.0375;

  /// Recargo base por placa extra (la 1.ª placa no paga), según material.
  static const double filamentPlateFee = 0.5;
  static const double resinPlateFee = 1.5;

  /// Objetivo de beneficio acumulado que muestra el panel.
  static const double profitGoal = 5000.0;

  // Valores antiguos de la app (< v3), solo para migrar sin pisar datos propios.
  static const double legacyProfitMarginPercent = 45.0;
  static const double legacyPaintingCostPerHour = 15.0;
}

/// Claves de la tabla `settings` (valores persistidos: no cambiar).
class SettingKeys {
  SettingKeys._();

  static const String profitMargin = 'margen_beneficio';
  static const String paintingCostPerHour = 'coste_hora_pintado';

  /// Obsoleta desde v3 (ya no se usa; se conserva la fila).
  static const String legacyPlateExtraCost = 'coste_placa_extra';

  static const String safetyMargin = 'margen_seguridad';
  static const String paintColorUnitCost = 'coste_unidad_color';
  static const String kwhCost = 'coste_kwh';
  static const String filamentPlateFee = 'tarifa_placa_filamento';
  static const String resinPlateFee = 'tarifa_placa_resina';
  static const String profitGoal = 'objetivo_beneficio';
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
