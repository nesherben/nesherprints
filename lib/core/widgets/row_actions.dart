import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/utils/responsive.dart';

/// Opción del menú «más» de una fila.
class RowMenuItem {
  const RowMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Acción destructiva: va al final, separada y en rojo.
  final bool danger;
}

/// Acciones de una fila de lista. En pantalla ancha, todas visibles como
/// iconos (menos clics); en móvil, una acción frecuente visible ([primary]) y
/// el resto en un menú ⋮. Todas las listas usan lo mismo para que se manejen
/// igual; tocar la propia fila abre la edición.
class RowActions extends StatelessWidget {
  const RowActions({super.key, this.primary, required this.items});

  final Widget? primary;
  final List<RowMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final normal = [
      for (final i in items)
        if (!i.danger) i,
    ];
    final danger = [
      for (final i in items)
        if (i.danger) i,
    ];
    final all = [...normal, ...danger];
    if (!context.isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?primary,
          for (final item in all)
            IconButton(
              tooltip: item.label,
              icon: Icon(item.icon, size: 20),
              color: item.danger ? AppColors.danger : AppColors.textMuted,
              visualDensity: VisualDensity.compact,
              onPressed: item.onTap,
            ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?primary,
        PopupMenuButton<int>(
          tooltip: AppStrings.moreActions,
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (i) => all[i].onTap(),
          itemBuilder: (_) => [
            for (final (i, item) in normal.indexed)
              PopupMenuItem(
                value: i,
                child: _MenuRow(item: item),
              ),
            if (normal.isNotEmpty && danger.isNotEmpty)
              const PopupMenuDivider(),
            for (final (i, item) in danger.indexed)
              PopupMenuItem(
                value: normal.length + i,
                child: _MenuRow(item: item),
              ),
          ],
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final RowMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.danger ? AppColors.danger : AppColors.textMain;
    return Row(
      children: [
        Icon(item.icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(item.label, style: TextStyle(color: color)),
      ],
    );
  }
}
