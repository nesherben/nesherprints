import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/order_repository.dart';

class StatusBadge extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onStatusChanged;

  const StatusBadge({
    super.key,
    required this.order,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    String status = order['status'];
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Completed':
      case 'Shipped':
        bgColor = AppColors.statusCompletado.withOpacity(0.2);
        textColor = AppColors.statusCompletado;
        break;
      case 'In Progress':
        bgColor = AppColors.primary.withOpacity(0.2);
        textColor = AppColors.primary;
        break;
      case 'Canceled':
        bgColor = AppColors.statusCancelado.withOpacity(0.2);
        textColor = AppColors.statusCancelado;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
    }

    return PopupMenuButton<String>(
      initialValue: status,
      tooltip: 'Cambiar estado rápidamente',
      onSelected: (String newStatus) async {
        if (newStatus == status) return;

        // ✅ COPIA DEFENSIVA: Evitar errores de read-only de SQLite
        final rawItems = await OrderRepository().getOrderItems(order['id']);
        final modifiableItems = rawItems
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final updatedOrder = Map<String, dynamic>.from(order);
        updatedOrder['status'] = newStatus;
        updatedOrder['items'] = modifiableItems;

        onStatusChanged(order, updatedOrder);
      },
      itemBuilder: (BuildContext context) {
        return ['Draft', 'Reserved', 'In Progress', 'Shipped', 'Canceled']
            .map(
              (String choice) =>
                  PopupMenuItem<String>(value: choice, child: Text(choice)),
            )
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (status != 'Completed') ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 14, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}
