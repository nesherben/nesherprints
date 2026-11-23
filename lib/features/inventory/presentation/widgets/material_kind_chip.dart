import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';

/// Etiqueta de color con el tipo de material.
class MaterialKindChip extends StatelessWidget {
  const MaterialKindChip({super.key, required this.kind});

  final MaterialKind kind;

  @override
  Widget build(BuildContext context) {
    final isResin = kind == MaterialKind.resin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isResin ? AppColors.resin : AppColors.filament).withValues(
          alpha: 0.2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isResin
            ? AppStrings.materialResinShort
            : AppStrings.materialFilamentShort,
        style: TextStyle(
          color: isResin ? AppColors.resinText : AppColors.filamentText,
          fontSize: 12,
        ),
      ),
    );
  }
}
