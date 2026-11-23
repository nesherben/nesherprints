import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';

/// Sección "Finanzas y Tiempos Extra" del formulario de pedido.
class FinanceSection extends StatelessWidget {
  const FinanceSection({
    super.key,
    required this.platesCount,
    required this.isPainted,
    required this.paintHoursController,
    required this.priceController,
    required this.paidController,
    required this.estimate,
    required this.isLocked,
    required this.onPaintedChanged,
    required this.onPaintHoursChanged,
    required this.onPriceChanged,
    required this.onApplySuggestedPrice,
  });

  final int platesCount;
  final bool isPainted;
  final TextEditingController paintHoursController;
  final TextEditingController priceController;
  final TextEditingController paidController;
  final PriceEstimate estimate;
  final bool isLocked;
  final ValueChanged<bool> onPaintedChanged;
  final VoidCallback onPaintHoursChanged;
  final VoidCallback onPriceChanged;
  final VoidCallback onApplySuggestedPrice;

  static Color _priceColor(PriceHealth health) => switch (health) {
    PriceHealth.neutral => AppColors.primary,
    PriceHealth.good => AppColors.success,
    PriceHealth.low => AppColors.warning,
    PriceHealth.loss => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final priceHealth = PriceHealth.evaluate(
      price: parseDecimal(priceController.text),
      estimate: estimate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(AppStrings.financesTitle, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),

        // Placas (automático) + pintura
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(platesCount),
                initialValue: '$platesCount',
                decoration: const InputDecoration(
                  labelText: AppStrings.totalPlatesAuto,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: Icon(Icons.layers, color: AppColors.textMuted),
                ),
                readOnly: true,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CheckboxListTile(
                title: const Text(AppStrings.paintServiceTitle),
                value: isPainted,
                onChanged: isLocked
                    ? null
                    : (v) => onPaintedChanged(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (isPainted) ...[
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: paintHoursController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.paintHoursLabel,
                    border: OutlineInputBorder(),
                    suffixText: 'h',
                  ),
                  keyboardType: decimalKeyboard,
                  readOnly: isLocked,
                  inputFormatters: decimalInputFormatters,
                  onChanged: (_) => onPaintHoursChanged(),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Coste, sugerido, precio final y cobrado
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.costManufacture,
                      style: AppTextStyles.mutedSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatEuro(estimate.totalCost),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      AppStrings.suggestedPrice,
                      style: AppTextStyles.mutedSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatEuro(estimate.suggestedPrice),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (!isLocked)
                      TextButton.icon(
                        onPressed: onApplySuggestedPrice,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text(AppStrings.apply),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.finalPriceLabel,
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _priceColor(priceHealth),
                  ),
                  onChanged: (_) => onPriceChanged(),
                  readOnly: isLocked,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: paidController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.paidAdvanceLabel,
                    border: OutlineInputBorder(),
                    prefixText: '€ ',
                  ),
                  keyboardType: decimalKeyboard,
                  readOnly: isLocked,
                  inputFormatters: decimalInputFormatters,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
