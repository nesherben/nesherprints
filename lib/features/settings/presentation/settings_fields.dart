import 'package:flutter/material.dart';

import 'package:nesherprints/core/constants/app_constants.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Hasta 6 decimales sin ceros sobrantes: `50` → `50`, `0.0375` → `0.0375`.
String formatSettingValue(double v) =>
    v.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');

/// Tarjetas en las que se agrupan los ajustes, en el orden de la pantalla
/// de una sola columna.
enum SettingGroup {
  price(
    AppStrings.settingsGroupPrice,
    AppStrings.settingsGroupPriceHint,
    Icons.sell_outlined,
  ),
  production(
    AppStrings.settingsGroupProduction,
    AppStrings.settingsGroupProductionHint,
    Icons.precision_manufacturing_outlined,
  ),
  paint(
    AppStrings.settingsGroupPaint,
    AppStrings.settingsGroupPaintHint,
    Icons.brush_outlined,
  ),
  goals(
    AppStrings.settingsGroupGoals,
    AppStrings.settingsGroupGoalsHint,
    Icons.flag_outlined,
  );

  const SettingGroup(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;

  List<SettingField> get fields => [
    for (final f in SettingField.values)
      if (f.group == this) f,
  ];
}

/// Ajustes editables, en el orden en que se muestran dentro de su tarjeta.
enum SettingField {
  profitMargin(
    SettingGroup.price,
    SettingKeys.profitMargin,
    AppStrings.profitMarginLabel,
    AppStrings.profitMarginHint,
    AppStrings.unitPercent,
    FinanceDefaults.profitMarginPercent,
    max: _maxMargin,
  ),
  minimumPrice(
    SettingGroup.price,
    SettingKeys.minimumPrice,
    AppStrings.minimumPriceLabel,
    AppStrings.minimumPriceHint,
    AppStrings.unitEuro,
    FinanceDefaults.minimumPrice,
  ),
  kwhPrice(
    SettingGroup.production,
    SettingKeys.kwhPrice,
    AppStrings.kwhPriceLabel,
    AppStrings.kwhPriceHint,
    AppStrings.unitEuroPerKwh,
    FinanceDefaults.kwhPrice,
  ),
  machineCost(
    SettingGroup.production,
    SettingKeys.machineCostPerHour,
    AppStrings.machineCostLabel,
    AppStrings.machineCostHint,
    AppStrings.unitEuroPerHour,
    FinanceDefaults.machineCostPerHour,
  ),
  plateCost(
    SettingGroup.production,
    SettingKeys.plateCost,
    AppStrings.plateCostLabel,
    AppStrings.plateCostHint,
    AppStrings.unitEuro,
    FinanceDefaults.plateCost,
  ),
  paintSimple(
    SettingGroup.paint,
    SettingKeys.paintPriceSimple,
    AppStrings.paintSimpleLabel,
    AppStrings.paintSimpleHint,
    AppStrings.unitEuro,
    FinanceDefaults.paintPriceSimple,
    max: _maxPaint,
  ),
  paintNormal(
    SettingGroup.paint,
    SettingKeys.paintPriceNormal,
    AppStrings.paintNormalLabel,
    AppStrings.paintNormalHint,
    AppStrings.unitEuro,
    FinanceDefaults.paintPriceNormal,
    max: _maxPaint,
  ),
  paintDetailed(
    SettingGroup.paint,
    SettingKeys.paintPriceDetailed,
    AppStrings.paintDetailedLabel,
    AppStrings.paintDetailedHint,
    AppStrings.unitEuro,
    FinanceDefaults.paintPriceDetailed,
    max: _maxPaint,
  ),
  profitGoal(
    SettingGroup.goals,
    SettingKeys.profitGoal,
    AppStrings.profitGoalLabel,
    AppStrings.profitGoalHint,
    AppStrings.unitEuro,
    FinanceDefaults.profitGoal,
  );

  const SettingField(
    this.group,
    this.key,
    this.label,
    this.hint,
    this.suffix,
    this.defaultValue, {
    this.max,
  });

  static const double _maxMargin = 1000;
  static const double _maxPaint = 1000;

  /// Dos números iguales a la precisión con la que se muestran.
  static const double _tolerance = 5e-7;

  final SettingGroup group;

  /// Clave en la tabla `settings`.
  final String key;
  final String label;
  final String hint;
  final String suffix;
  final double defaultValue;

  /// Tope opcional (el margen y los importes de pintura).
  final double? max;

  double valueOf(PricingSettings s) => s.toMap()[key]!;

  /// Número escrito (coma o punto), o `null` si no es un número válido.
  double? parse(String text) {
    final v = double.tryParse(text.replaceAll(',', '.').trim());
    return v != null && v.isFinite ? v : null;
  }

  /// Texto de error del campo, o `null` si es válido.
  String? validate(String text) {
    if (text.trim().isEmpty) return AppStrings.settingsErrorRequired;
    final v = parse(text);
    if (v == null) return AppStrings.settingsErrorInvalid;
    if (v < 0) return AppStrings.settingsErrorNegative;
    if (max != null && v > max!) return AppStrings.settingsErrorTooBig(max!);
    return null;
  }

  /// `true` si [v] coincide con [other] a la precisión mostrada.
  static bool sameValue(double? v, double other) =>
      v != null && (v - other).abs() < _tolerance;
}
