import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/domain/resin_blend.dart';

/// Echa resina al tanque: gramos y precio de la remesa, con el precio medio
/// resultante a la vista.
class AddResinDialog extends StatefulWidget {
  const AddResinDialog({
    super.key,
    required this.material,
    required this.onConfirm,
  });

  final PrintMaterial material;
  final void Function(double grams, double pricePerKg) onConfirm;

  @override
  State<AddResinDialog> createState() => _AddResinDialogState();
}

class _AddResinDialogState extends State<AddResinDialog> {
  final _gramsController = TextEditingController();
  late final TextEditingController _priceController = TextEditingController(
    // Con el tanque vacío no hay precio que sugerir.
    text: widget.material.costPerKg > 0
        ? widget.material.costPerKg.toString()
        : '',
  );

  double get _grams => parseDecimal(_gramsController.text);
  double get _price => parseDecimal(_priceController.text, fallback: -1);
  bool get _canApply => _grams > 0 && _price >= 0;

  double get _newPrice => ResinBlend.weightedPricePerKg(
    currentGrams: widget.material.stockGrams,
    currentPricePerKg: widget.material.costPerKg,
    addedGrams: _grams,
    addedPricePerKg: _price < 0 ? 0 : _price,
  );

  @override
  void dispose() {
    _gramsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_canApply) return;
    widget.onConfirm(_grams, _price);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    final owned = m.stockGrams < 0 ? 0.0 : m.stockGrams;
    return AppDialogFrame(
      title: AppStrings.addResinTo(m.name),
      subtitle: AppStrings.resinNow(
        AppStrings.kilos(owned),
        formatEuro(m.costPerKg),
      ),
      icon: Icons.water_drop,
      iconColor: AppColors.resinText,
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
                  controller: _gramsController,
                  autofocus: true,
                  keyboardType: decimalKeyboard,
                  inputFormatters: decimalInputFormatters,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: AppStrings.resinGramsLabel,
                    prefixIcon: Icon(Icons.scale_outlined, size: 20),
                    suffixText: 'g',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: decimalKeyboard,
                  inputFormatters: decimalInputFormatters,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _apply(),
                  decoration: const InputDecoration(
                    labelText: AppStrings.resinBatchPriceLabel,
                    prefixIcon: Icon(Icons.euro, size: 20),
                    suffixText: '€/kg',
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
                        label: AppStrings.resinPriceNow,
                        value: formatEuro(m.costPerKg),
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
                        label: AppStrings.resinPriceNew,
                        value: formatEuro(_canApply ? _newPrice : m.costPerKg),
                        color: _canApply
                            ? AppColors.resinText
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _canApply
                      ? AppStrings.resinAfter(AppStrings.kilos(owned + _grams))
                      : AppStrings.resinApplyHint,
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
          '$value/kg',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardTitle.copyWith(fontSize: 20, color: color),
        ),
      ],
    );
  }
}
