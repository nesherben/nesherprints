import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/presentation/status_style.dart';

/// Etiqueta de estado. Si el estado admite cambios rápidos
/// ([OrderStatus.quickChangeTargets]) se abre un menú al pulsarla; los
/// pedidos cerrados no se pueden reabrir.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.onChanged});

  final OrderStatus status;
  final ValueChanged<OrderStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final targets = status.quickChangeTargets;

    if (targets.isEmpty) {
      return StatusPill(
        label: status.label,
        color: color,
        icon: statusIcon(status),
      );
    }

    return PopupMenuButton<OrderStatus>(
      tooltip: AppStrings.changeStatusTooltip,
      position: PopupMenuPosition.under,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final s in targets)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(statusIcon(s), size: 18, color: statusColor(s)),
                const SizedBox(width: 10),
                Text(s.label),
              ],
            ),
          ),
      ],
      child: StatusPill(
        label: status.label,
        color: color,
        icon: statusIcon(status),
        trailing: Icon(Icons.expand_more, size: 16, color: color),
      ),
    );
  }
}
