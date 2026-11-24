/// Valores por defecto de la calculadora de precios. Se calibraron con los
/// precios que el usuario cobraba (ver docs/SPEC.md §4.2).
class FinanceDefaults {
  FinanceDefaults._();

  /// Margen sobre el coste: precio recomendado = coste × (1 + margen/100).
  static const double profitMarginPercent = 150.0;

  /// Precio de la electricidad (€/kWh).
  static const double kwhPrice = 0.15;

  /// Desgaste y amortización aproximados de la máquina (€ por hora de
  /// impresión), sin contar la electricidad.
  static const double machineCostPerHour = 0.10;

  /// Preparación y retirada de cada placa (laminado, cama, quitar soportes).
  static const double plateCost = 1.0;

  /// Pintura: mano de obra y material, por hora de trabajo.
  static const double paintingCostPerHour = 10.0;

  /// El precio recomendado nunca baja de esto.
  static const double minimumPrice = 5.0;

  /// Objetivo de beneficio acumulado que muestra el panel.
  static const double profitGoal = 5000.0;
}

/// Constantes físicas de la calculadora que no se configuran.
class PricingConstants {
  PricingConstants._();

  /// Potencia media de la impresora en funcionamiento (kW). Con
  /// [FinanceDefaults.kwhPrice] da unos 0,04 €/h de electricidad.
  static const double printerKw = 0.25;
}

/// Claves de la tabla `settings` (valores persistidos: no cambiar).
class SettingKeys {
  SettingKeys._();

  // Vigentes
  static const String profitMargin = 'margen_beneficio';
  static const String kwhPrice = 'precio_kwh';
  static const String machineCostPerHour = 'coste_maquina_hora';
  static const String plateCost = 'coste_placa';
  static const String paintingCostPerHour = 'coste_hora_pintado';
  static const String minimumPrice = 'precio_minimo';
  static const String profitGoal = 'objetivo_beneficio';

  // Obsoletas: de versiones anteriores del modelo de precios. Se conservan
  // las filas pero no se usan.
  static const List<String> obsolete = [
    'coste_placa_extra',
    'margen_seguridad',
    'coste_unidad_color',
    'coste_pintura_pocos',
    'coste_pintura_normal',
    'coste_pintura_muchos',
    'coste_kwh',
    'tarifa_placa_filamento',
    'tarifa_placa_resina',
  ];
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
