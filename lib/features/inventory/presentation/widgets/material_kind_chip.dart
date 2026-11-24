import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';

/// Colores e iconos de cada tipo de material.
extension MaterialKindStyle on MaterialKind {
  bool get isResin => this == MaterialKind.resin;

  /// Color de fondo/acento del tipo.
  Color get tint => isResin ? AppColors.resin : AppColors.filament;

  /// Color de texto legible sobre el fondo tintado.
  Color get textTint => isResin ? AppColors.resinText : AppColors.filamentText;

  IconData get icon => isResin ? Icons.water_drop : Icons.donut_large;

  String get shortLabel => isResin
      ? AppStrings.materialResinShort
      : AppStrings.materialFilamentShort;
}

/// Etiqueta de color con el tipo de material.
class MaterialKindChip extends StatelessWidget {
  const MaterialKindChip({super.key, required this.kind});

  final MaterialKind kind;

  @override
  Widget build(BuildContext context) =>
      StatusPill(label: kind.shortLabel, color: kind.textTint);
}
