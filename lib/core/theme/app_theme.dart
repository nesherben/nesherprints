import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_colors.dart';

/// Tema global de la aplicación.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 4,
      margin: EdgeInsets.all(8),
    ),
    useMaterial3: true,
  );
}

/// Estilos de texto reutilizados en varias pantallas.
class AppTextStyles {
  AppTextStyles._();

  static const pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );

  static const pageSubtitle = TextStyle(color: AppColors.textMuted);

  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );

  static const cardTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  static const muted = TextStyle(color: AppColors.textMuted);

  static const mutedSmall = TextStyle(color: AppColors.textMuted, fontSize: 12);

  static const tableHeading = TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );
}

/// Estilos de botón reutilizados.
class AppButtonStyles {
  AppButtonStyles._();

  static final primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.background,
  );

  static ButtonStyle filled(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: AppColors.onAccent,
  );
}
