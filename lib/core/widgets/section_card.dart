import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';

/// Tarjeta con título (y subtítulo, icono y acción opcionales) para agrupar
/// contenido en formularios y ajustes.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // En estrecho la acción baja bajo el título para no apretarlo.
                final stacked = trailing != null && constraints.maxWidth < 420;
                final heading = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(icon, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.sectionTitle),
                          if (subtitle != null)
                            Text(subtitle!, style: AppTextStyles.mutedSmall),
                        ],
                      ),
                    ),
                    if (!stacked) ?trailing,
                  ],
                );
                if (!stacked) return heading;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    Align(alignment: Alignment.centerLeft, child: trailing!),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
