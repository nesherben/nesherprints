import 'package:flutter/widgets.dart';

/// Puntos de corte de la interfaz.
class Breakpoints {
  Breakpoints._();

  /// Por debajo: móvil (barra de navegación inferior, una columna).
  static const double compact = 720;

  /// Desde aquí: barra lateral extendida (con textos) y más aire.
  static const double wide = 1100;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => screenWidth < Breakpoints.compact;
  bool get isWide => screenWidth >= Breakpoints.wide;
}
