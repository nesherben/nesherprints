import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Tarjeta de una pieza: nombre, precio unitario, stock y acciones.
class ExtraCard extends StatelessWidget {
  const ExtraCard({
    super.key,
    required this.extra,
    required this.onEdit,
    required this.onAddStock,
    required this.onDelete,
  });

  /// Alto fijo de la tarjeta dentro de la rejilla.
  static const double height = 132;

  final Extra extra;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;
  final VoidCallback onDelete;

  /// Etiqueta y color según el nivel de stock (`null` si no hay aviso).
  (String, Color)? get _alert => switch (extra.stockLevel) {
    ExtraStockLevel.negative => (
      AppStrings.extraNegativeStock,
      AppColors.danger,
    ),
    ExtraStockLevel.soldOut => (AppStrings.extraSoldOut, AppColors.danger),
    ExtraStockLevel.few => (AppStrings.extraFewUnits, AppColors.warning),
    ExtraStockLevel.ok => null,
  };

  @override
  Widget build(BuildContext context) {
    final alert = _alert;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        extra.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      Text(
                        AppStrings.perUnit(formatEuro(extra.unitPrice)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    AppStrings.units(extra.stock),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.kpiValue.copyWith(
                      fontSize: 22,
                      color: alert?.$2 ?? AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: alert == null
                        ? null
                        : StatusPill(label: alert.$1, color: alert.$2),
                  ),
                ),
                IconButton(
                  onPressed: onAddStock,
                  icon: const Icon(Icons.add_box_outlined),
                  color: AppColors.success,
                  tooltip: AppStrings.addStock,
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.info,
                  tooltip: AppStrings.edit,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.danger,
                  tooltip: AppStrings.delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
