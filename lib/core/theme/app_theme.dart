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
