import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Nivel de detalle de una figura pintada. Cada nivel tiene un importe (€)
/// que el usuario configura y que se suma al precio de la pieza sin pintar.
enum PaintDetail {
  simple(0),
  normal(1),
  detailed(2);

  const PaintDetail(this.dbValue);

  /// Valor guardado en `orders.paint_level` (no cambiar).
  final int dbValue;

  /// Importe de la pintura de este nivel según los ajustes (€).
  double priceOf(PricingSettings settings) => switch (this) {
    simple => settings.paintPriceSimple,
    normal => settings.paintPriceNormal,
    detailed => settings.paintPriceDetailed,
  };

  static PaintDetail fromDb(Object? value) => PaintDetail.values.firstWhere(
    (d) => d.dbValue == value,
    orElse: () => PaintDetail.normal,
  );
}
