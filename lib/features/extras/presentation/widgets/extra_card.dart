import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Fila de una pieza: nombre, precio, stock y acciones.
class ExtraCard extends StatelessWidget {
  const ExtraCard({
    super.key,
    required this.extra,
    required this.onEdit,
    required this.onAddStock,
    required this.onDelete,
  });

  final Extra extra;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    extra.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formatEuro(extra.unitPrice),
                        style: AppTextStyles.muted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.units(extra.stock),
                        style: AppTextStyles.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              color: AppColors.primary,
              tooltip: AppStrings.edit,
            ),
            IconButton(
              onPressed: onAddStock,
              icon: const Icon(Icons.add_box),
              color: AppColors.success,
              tooltip: AppStrings.addStock,
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete),
              color: AppColors.danger,
              tooltip: AppStrings.delete,
            ),
          ],
        ),
      ),
    );
  }
}
