import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/responsive.dart';

/// Cabecera estándar de pantalla: título, subtítulo opcional y acciones.
/// En ventanas estrechas las acciones pasan debajo del título.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;

  /// Una sola acción (atajo de [actions]).
  final Widget? action;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final trailing = [?action, ...actions];
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.pageTitle),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTextStyles.pageSubtitle),
        ],
      ],
    );

    if (trailing.isEmpty) return titleBlock;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Con poco ancho las acciones pasan debajo del título (móvil, o una
        // ventana estrecha de escritorio).
        final stacked = context.isCompact || constraints.maxWidth < 960;
        return _layout(titleBlock, trailing, stacked);
      },
    );
  }

  Widget _layout(Widget titleBlock, List<Widget> trailing, bool stacked) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: trailing,
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: AppSpacing.lg),
        for (final (i, w) in trailing.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          w,
        ],
      ],
    );
  }
}
