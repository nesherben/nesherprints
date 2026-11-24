import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/section_card.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Sección de piezas extra del formulario: contador −/+ por pieza.
class ExtrasSection extends StatelessWidget {
  const ExtrasSection({
    super.key,
    required this.extras,
    required this.unitPrices,
    required this.selected,
    required this.isLocked,
    required this.onQuantityChanged,
  });

  final List<Extra> extras;

  /// Precio unitario que se aplica a cada pieza (el registrado en el pedido
  /// si ya la tenía, o el actual).
  final Map<int, double> unitPrices;

  /// Cantidad elegida por id de pieza (solo > 0).
  final Map<int, int> selected;
  final bool isLocked;
  final void Function(int extraId, int quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final total = [
      for (final e in selected.entries) (unitPrices[e.key] ?? 0) * e.value,
    ].fold(0.0, (a, b) => a + b);

    return SectionCard(
      title: AppStrings.extrasSectionTitle,
      subtitle: AppStrings.extrasSectionHint,
      icon: Icons.category_outlined,
      trailing: selected.isEmpty
          ? null
          : Text(
              AppStrings.extrasTotal(formatEuro(total)),
              style: AppTextStyles.money,
            ),
      child: extras.isEmpty
          ? const Text(AppStrings.noExtrasDefined, style: AppTextStyles.muted)
          : Column(
              children: [
                for (final (i, extra) in extras.indexed) ...[
                  if (i > 0) const Divider(),
                  _ExtraRow(
                    extra: extra,
                    unitPrice: unitPrices[extra.id] ?? extra.unitPrice,
                    quantity: selected[extra.id] ?? 0,
                    isLocked: isLocked,
                    onChanged: (q) => onQuantityChanged(extra.id!, q),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    required this.extra,
    required this.unitPrice,
    required this.quantity,
    required this.isLocked,
    required this.onChanged,
  });

  final Extra extra;
  final double unitPrice;
  final int quantity;
  final bool isLocked;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final overStock = quantity > extra.stock;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extra.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  overStock
                      ? AppStrings.extraNotEnough(extra.stock)
                      : AppStrings.extraPriceStock(
                          formatEuro(unitPrice),
                          extra.stock,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: overStock ? AppColors.warning : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.removeOne,
            onPressed: isLocked || quantity <= 0
                ? null
                : () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.money.copyWith(
                color: quantity > 0 ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.addOne,
            onPressed: isLocked ? null : () => onChanged(quantity + 1),
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
