import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/inline_edit_cell.dart';
import 'package:nesherprints/core/widgets/row_actions.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Fila compacta de una pieza: nombre y precio unitario, aviso de stock,
/// unidades y acciones.
class ExtraRow extends StatelessWidget {
  const ExtraRow({
    super.key,
    required this.extra,
    required this.onEdit,
    required this.onAddStock,
    required this.onDelete,
    this.onSetStock,
  });

  final Extra extra;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;
  final VoidCallback onDelete;

  /// Corrección rápida del stock pulsando las unidades.
  final Future<void> Function(int stock)? onSetStock;

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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 84,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      InlineMoneyCell(
                        value: extra.stock.toDouble(),
                        integer: true,
                        suffix: 'uds',
                        alignEnd: true,
                        enabled: onSetStock != null,
                        tooltip: AppStrings.editStockTip,
                        onSubmit: (v) => onSetStock!(v.round()),
                        display: Text(
                          AppStrings.units(extra.stock),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: alert?.$2 ?? AppColors.textMain,
                          ),
                        ),
                      ),
                      if (alert != null)
                        Text(
                          alert.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: alert.$2,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onAddStock,
                  icon: const Icon(Icons.add_box_outlined, size: 22),
                  color: AppColors.success,
                  tooltip: AppStrings.addStock,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                ),
                RowActions(
                  items: [
                    RowMenuItem(
                      icon: Icons.edit_outlined,
                      label: AppStrings.edit,
                      onTap: onEdit,
                    ),
                    RowMenuItem(
                      icon: Icons.delete_outline,
                      label: AppStrings.delete,
                      onTap: onDelete,
                      danger: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
