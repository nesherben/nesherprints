import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Suma unidades compradas a una pieza mostrando el nuevo precio medio.
class AddStockDialog extends StatefulWidget {
  const AddStockDialog({
    super.key,
    required this.extra,
    required this.onConfirm,
  });

  final Extra extra;
  final void Function(int addedUnits, double addedTotalPrice) onConfirm;

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _unitsController = TextEditingController();
  final _totalPriceController = TextEditingController();

  int get _addedUnits => parseInt(_unitsController.text);
  double get _addedTotal => parseDecimal(_totalPriceController.text);
  bool get _canApply => _addedUnits > 0 && _addedTotal >= 0;

  double get _newUnitPrice => ExtraPricing.weightedUnitPrice(
    currentStock: widget.extra.stock,
    currentUnitPrice: widget.extra.unitPrice,
    addedUnits: _addedUnits,
    addedTotal: _addedTotal,
  );

  @override
  void dispose() {
    _unitsController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_canApply) return;
    widget.onConfirm(_addedUnits, _addedTotal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final extra = widget.extra;
    final currentStock = extra.stock < 0 ? 0 : extra.stock;
    return AppDialogFrame(
      title: AppStrings.addUnitsTo(extra.name),
      subtitle: AppStrings.currentStock(
        extra.stock,
        formatEuro(extra.unitPrice),
      ),
      icon: Icons.add_box_outlined,
      iconColor: AppColors.success,
      width: 460,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _canApply ? _apply : null,
          child: const Text(AppStrings.apply),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _unitsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: AppStrings.addUnits,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextField(
                  controller: _totalPriceController,
                  keyboardType: decimalKeyboard,
                  inputFormatters: decimalInputFormatters,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _apply(),
                  decoration: const InputDecoration(
                    labelText: AppStrings.totalPriceOfUnits,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PriceColumn(
                        label: AppStrings.stockUnitPriceNow,
                        value: formatEuro(extra.unitPrice, decimals: 4),
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: _PriceColumn(
                        label: AppStrings.stockUnitPriceNew,
                        value: formatEuro(_newUnitPrice, decimals: 4),
                        color: _canApply
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _canApply
                      ? AppStrings.stockAfter(currentStock + _addedUnits)
                      : AppStrings.stockApplyHint,
                  style: AppTextStyles.mutedSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.mutedSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardTitle.copyWith(fontSize: 20, color: color),
        ),
      ],
    );
  }
}
