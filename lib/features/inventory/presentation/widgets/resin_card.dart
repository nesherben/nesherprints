import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/row_actions.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/resin_tank.dart';

/// El tanque de resina: nivel animado a la izquierda y, a su lado, el total,
/// el precio medio, el valor y el botón para echar más.
class ResinCard extends StatelessWidget {
  const ResinCard({
    super.key,
    required this.material,
    required this.onAdd,
    this.onEdit,
    this.onDelete,
  });

  final PrintMaterial material;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Widget _menu() => RowActions(
    items: [
      RowMenuItem(
        icon: Icons.edit_outlined,
        label: AppStrings.edit,
        onTap: onEdit!,
      ),
      RowMenuItem(
        icon: Icons.delete_outline,
        label: AppStrings.delete,
        onTap: onDelete!,
        danger: true,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final stock = material.stockGrams < 0 ? 0.0 : material.stockGrams;
    final value = stock / 1000 * material.costPerKg;
    final compact = MediaQuery.sizeOf(context).width < 720;

    final stats = [
      _Stat(
        dense: compact,
        icon: Icons.scale_outlined,
        label: AppStrings.resinStatAmount,
        value: AppStrings.kilos(stock),
        hint: AppStrings.grams(stock),
        color: AppColors.resinText,
      ),
      _Stat(
        dense: compact,
        icon: Icons.sell_outlined,
        label: AppStrings.resinPriceNow,
        value: formatEuro(material.costPerKg),
        hint: AppStrings.perKg,
      ),
      _Stat(
        dense: compact,
        icon: Icons.account_balance_wallet_outlined,
        label: AppStrings.resinStatValue,
        value: formatEuro(value),
        hint: AppStrings.resinStatValueHint,
      ),
    ];

    if (compact) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.resinTankTitle,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
                      ),
                    ),
                    if (onEdit != null && onDelete != null) _menu(),
                  ],
                ),
                const Text(
                  AppStrings.resinTankSubtitle,
                  style: AppTextStyles.mutedSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    ResinTank(
                      stockGrams: material.stockGrams,
                      width: 92,
                      height: 128,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        children: [
                          for (final (i, s) in stats.indexed) ...[
                            if (i > 0) const SizedBox(height: AppSpacing.sm),
                            s,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.addResin),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ResinTank(stockGrams: material.stockGrams),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.resinTankTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (onEdit != null && onDelete != null)
                          RowActions(
                            items: [
                              RowMenuItem(
                                icon: Icons.edit_outlined,
                                label: AppStrings.edit,
                                onTap: onEdit!,
                              ),
                              RowMenuItem(
                                icon: Icons.delete_outline,
                                label: AppStrings.delete,
                                onTap: onDelete!,
                                danger: true,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      AppStrings.resinTankSubtitle,
                      style: AppTextStyles.muted,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (compact)
                      Column(
                        children: [
                          for (final s in stats) ...[
                            s,
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      )
                    else
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, s) in stats.indexed) ...[
                              if (i > 0) const SizedBox(width: AppSpacing.md),
                              Expanded(child: s),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(AppStrings.addResin),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dato del tanque en una casilla: icono, etiqueta, cifra y nota.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.color = AppColors.textMain,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final Color color;

  /// Una sola línea (móvil): icono, etiqueta y cifra.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.mutedSmall,
              ),
            ),
            Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.mutedSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.kpiValue.copyWith(
                fontSize: 24,
                color: color,
              ),
            ),
          ),
          Text(hint, style: AppTextStyles.mutedSmall),
        ],
      ),
    );
  }
}
