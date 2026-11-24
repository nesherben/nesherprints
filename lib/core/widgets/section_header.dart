import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';

/// Cabecera de sección: icono, título en mayúsculas pequeñas, dato opcional
/// en gris y acción a la derecha. Sirve para separar bloques dentro de una
/// misma tarjeta o panel.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.meta,
    this.trailing,
  });

  final String title;
  final IconData icon;

  /// Dato breve a la derecha del título (por ejemplo «3 placas · 2 h»).
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(title.toUpperCase(), style: AppTextStyles.overline),
        if (meta != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              meta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.mutedSmall,
            ),
          ),
        ] else
          const Spacer(),
        ?trailing,
      ],
    );
  }
}
