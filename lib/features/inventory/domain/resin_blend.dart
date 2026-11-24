import 'dart:math' as math;

/// Cálculos del tanque de resina (lógica pura).
class ResinBlend {
  ResinBlend._();

  /// Capacidad mínima con la que se dibuja el tanque (g).
  static const double baseCapacityGrams = 5000;

  /// Precio medio por kilo al mezclar lo que hay ([currentGrams] a
  /// [currentPricePerKg]) con lo que se añade. Un stock negativo cuenta como
  /// 0; si no queda nada, se mantiene el precio actual.
  static double weightedPricePerKg({
    required double currentGrams,
    required double currentPricePerKg,
    required double addedGrams,
    required double addedPricePerKg,
  }) {
    final owned = math.max(0.0, currentGrams);
    final total = owned + addedGrams;
    if (total <= 0) return currentPricePerKg;
    return (currentPricePerKg * owned + addedPricePerKg * addedGrams) / total;
  }

  /// Capacidad con la que se dibuja el tanque: 5 kg, o el siguiente kilo
  /// entero si hay más.
  static double tankCapacity(double stockGrams) {
    if (stockGrams <= baseCapacityGrams) return baseCapacityGrams;
    return (stockGrams / 1000).ceil() * 1000.0;
  }

  /// Nivel del tanque entre 0 y 1.
  static double level(double stockGrams) =>
      (math.max(0.0, stockGrams) / tankCapacity(stockGrams)).clamp(0.0, 1.0);
}
