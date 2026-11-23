import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_theme.dart';

/// Cabecera estándar de pantalla: título, subtítulo opcional y acción a la derecha.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.pageTitle),
              if (subtitle != null)
                Text(subtitle!, style: AppTextStyles.pageSubtitle),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}
