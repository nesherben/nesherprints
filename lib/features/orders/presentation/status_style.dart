import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Color con el que se muestra cada estado de pedido en toda la app.
Color statusColor(OrderStatus status) => switch (status) {
  OrderStatus.draft => AppColors.neutral,
  OrderStatus.reserved => AppColors.info,
  OrderStatus.inProgress => AppColors.primary,
  OrderStatus.completed => AppColors.success,
  OrderStatus.shipped => AppColors.resinText,
  OrderStatus.canceled => AppColors.danger,
};

/// Icono de cada estado.
IconData statusIcon(OrderStatus status) => switch (status) {
  OrderStatus.draft => Icons.edit_note,
  OrderStatus.reserved => Icons.bookmark_border,
  OrderStatus.inProgress => Icons.print_outlined,
  OrderStatus.completed => Icons.check_circle_outline,
  OrderStatus.shipped => Icons.local_shipping_outlined,
  OrderStatus.canceled => Icons.cancel_outlined,
};
