import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_kind_chip.dart';

/// Tarjeta de un material: tipo, nombre, color, precio y barra de stock.
class MaterialCard extends StatelessWidget {
  const MaterialCard({
    super.key,
    required this.material,
    required this.onEdit,
    required this.onDelete,
  });

  /// Alto fijo de la tarjeta dentro de la rejilla.
  static const double height = 184;

  /// Stock (g) que llena la barra.
  static const double _fullBarGrams = 1000;

  final PrintMaterial material;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _stockColor {
    if (material.stockGrams <= 0) return AppColors.danger;
    if (material.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final kind = material.kind;
    final stockColor = _stockColor;
    final color = material.color.isEmpty ? AppStrings.noData : material.color;
    final price = AppStrings.pricePerKg(formatEuro(material.costPerKg));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kind.tint.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(kind.icon, color: kind.textTint),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      Text(
                        '$color · $price',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.muted,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.info,
                  tooltip: AppStrings.edit,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.danger,
                  tooltip: AppStrings.delete,
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                MaterialKindChip(kind: kind),
                if (material.isLowStock)
                  const StatusPill(
                    label: AppStrings.lowStock,
                    color: AppColors.warning,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              AppStrings.grams(material.stockGrams),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle.copyWith(color: stockColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: (material.stockGrams / _fullBarGrams).clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: stockColor,
              backgroundColor: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
