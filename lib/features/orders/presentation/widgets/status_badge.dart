import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Etiqueta de estado con menú para cambiarlo rápidamente.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.onChanged});

  final OrderStatus status;
  final ValueChanged<OrderStatus> onChanged;

  static Color _color(OrderStatus status) => switch (status) {
    OrderStatus.completed || OrderStatus.shipped => AppColors.success,
    OrderStatus.inProgress => AppColors.primary,
    OrderStatus.canceled => AppColors.danger,
    _ => AppColors.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return PopupMenuButton<OrderStatus>(
      initialValue: status,
      tooltip: AppStrings.changeStatusTooltip,
      onSelected: (newStatus) {
        if (newStatus != status) onChanged(newStatus);
      },
      itemBuilder: (_) => [
        for (final s in OrderStatus.manualChoices)
          PopupMenuItem(value: s, child: Text(s.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (status != OrderStatus.completed) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
