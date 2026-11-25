import 'package:flutter/widgets.dart';

/// Puntos de corte de la interfaz.
class Breakpoints {
  Breakpoints._();

  /// Por debajo: móvil (barra de navegación inferior, una columna).
  static const double compact = 720;

  /// Desde aquí caben las barras de alta rápida sobre las listas.
  static const double quickBars = 900;

  /// Desde aquí: barra lateral extendida (con textos) y más aire.
  static const double wide = 1100;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => screenWidth < Breakpoints.compact;
  bool get isWide => screenWidth >= Breakpoints.wide;

  /// Hay sitio para las barras de alta rápida (una fila de campos).
  bool get showQuickBars => screenWidth >= Breakpoints.quickBars;
}
