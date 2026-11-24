import 'package:flutter/material.dart';

/// Paleta de la app (tema oscuro). Usar siempre estos colores en la UI.
///
/// Escala de superficies, de más oscura a más clara:
/// [background] < [surface] < [surfaceHigh] < [secondary].
class AppColors {
  AppColors._();

  // Marca
  static const Color primary = Color(0xFF1FC7CF);
  static const Color onPrimary = Color(0xFF04262B);

  // Superficies
  static const Color background = Color(0xFF12161C);
  static const Color surface = Color(0xFF1A1F27);
  static const Color surfaceHigh = Color(0xFF232A34);
  static const Color secondary = Color(0xFF2A313C);
  static const Color border = Color(0xFF2C3440);

  // Texto
  static const Color textMain = Color(0xFFE6E9EE);
  static const Color textMuted = Color(0xFF8E97A5);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Semánticos
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerBright = Color(0xFFFCA5A5);
  static const Color info = Color(0xFF60A5FA);
  static const Color neutral = Color(0xFF94A3B8);

  // Tipos de material
  static const Color resin = Color(0xFF8B5CF6);
  static const Color resinText = Color(0xFFC4B5FD);
  static const Color filament = Color(0xFFF59E0B);
  static const Color filamentText = Color(0xFFFCD34D);
}
