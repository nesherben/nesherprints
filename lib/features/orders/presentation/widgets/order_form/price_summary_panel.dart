import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';

/// Panel fijo del formulario de pedido: desglose del coste, precio
/// recomendado, precio final con su valoración y cobro.
class PriceSummaryPanel extends StatelessWidget {
  const PriceSummaryPanel({
    super.key,
    required this.estimate,
    required this.attempts,
    required this.plateCount,
    required this.totalMinutes,
    required this.totalGrams,
    required this.priceController,
    required this.paidController,
    required this.isLocked,
    required this.onPriceChanged,
    required this.onPaidChanged,
    required this.onApplySuggested,
    required this.onSetPaid,
  });

  final PriceEstimate estimate;
  final double attempts;
  final int plateCount;
  final double totalMinutes;
  final double totalGrams;
  final TextEditingController priceController;
  final TextEditingController paidController;
  final bool isLocked;
  final VoidCallback onPriceChanged;
  final VoidCallback onPaidChanged;
  final VoidCallback onApplySuggested;

  /// Pone el importe cobrado (los atajos 0 / 50 % / todo).
  final ValueChanged<double> onSetPaid;

  @override
  Widget build(BuildContext context) {
    final price = parseDecimal(priceController.text);
    final paid = parseDecimal(paidController.text);
    final health = PriceHealth.evaluate(price: price, estimate: estimate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(AppStrings.summaryTitle, style: AppTextStyles.overline),
        const SizedBox(height: 2),
        Text(
          AppStrings.summaryMeta(
            plateCount,
            formatDuration(totalMinutes),
            totalGrams,
          ),
          style: AppTextStyles.mutedSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _Breakdown(estimate: estimate, attempts: attempts),
        const SizedBox(height: AppSpacing.lg),
        _Recommended(
          value: estimate.suggestedPrice,
          minimumApplied: estimate.minimumApplied,
          showApply: !isLocked && estimate.suggestedPrice > 0,
          onApply: onApplySuggested,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: priceController,
          readOnly: isLocked,
          keyboardType: decimalKeyboard,
          inputFormatters: decimalInputFormatters,
          onChanged: (_) => onPriceChanged(),
          style: AppTextStyles.kpiValue.copyWith(fontSize: 22),
          decoration: const InputDecoration(
            labelText: AppStrings.finalPriceLabel,
            prefixText: '€ ',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _HealthMessage(health: health, price: price, estimate: estimate),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: paidController,
          readOnly: isLocked,
          keyboardType: decimalKeyboard,
          inputFormatters: decimalInputFormatters,
          onChanged: (_) => onPaidChanged(),
          decoration: const InputDecoration(
            labelText: AppStrings.paidAdvanceLabel,
            prefixText: '€ ',
          ),
        ),
        if (!isLocked) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ActionChip(
                label: const Text(AppStrings.quickPaidNone),
                onPressed: () => onSetPaid(0),
              ),
              ActionChip(
                label: const Text(AppStrings.quickPaidHalf),
                onPressed: () => onSetPaid(price / 2),
              ),
              ActionChip(
                label: const Text(AppStrings.quickPaidAll),
                onPressed: () => onSetPaid(price),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _PendingLine(price: price, paid: paid),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.estimate, required this.attempts});

  final PriceEstimate estimate;
  final double attempts;

  @override
  Widget build(BuildContext context) {
    final lines = <(String, double)>[
      (AppStrings.lineMaterial, estimate.materialCost),
      (AppStrings.lineMachine, estimate.machineCost),
      if (estimate.platesCost > 0) (AppStrings.linePlates, estimate.platesCost),
      if (estimate.paintCost > 0) (AppStrings.linePaint, estimate.paintCost),
      if (estimate.extrasCost > 0) (AppStrings.lineExtras, estimate.extrasCost),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final (label, amount) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: AppTextStyles.muted)),
                  Text(
                    formatEuro(amount),
                    style: AppTextStyles.money.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (attempts != 1)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.attemptsNote(formatInputNumber(attempts)),
                  style: AppTextStyles.mutedSmall.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(
                child: Text(
                  AppStrings.costReal,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(formatEuro(estimate.cost), style: AppTextStyles.money),
            ],
          ),
        ],
      ),
    );
  }
}

class _Recommended extends StatelessWidget {
  const _Recommended({
    required this.value,
    required this.minimumApplied,
    required this.showApply,
    required this.onApply,
  });

  final double value;
  final bool minimumApplied;
  final bool showApply;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.suggestedPrice,
                  style: AppTextStyles.mutedSmall,
                ),
                Text(
                  formatEuro(value),
                  style: AppTextStyles.kpiValue.copyWith(
                    fontSize: 26,
                    color: AppColors.primary,
                  ),
                ),
                if (minimumApplied)
                  const Text(
                    AppStrings.minimumNote,
                    style: AppTextStyles.mutedSmall,
                  ),
              ],
            ),
          ),
          if (showApply)
            FilledButton.tonal(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                foregroundColor: AppColors.primary,
              ),
              child: const Text(AppStrings.apply),
            ),
        ],
      ),
    );
  }
}

class _HealthMessage extends StatelessWidget {
  const _HealthMessage({
    required this.health,
    required this.price,
    required this.estimate,
  });

  final PriceHealth health;
  final double price;
  final PriceEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final benefit = price - estimate.cost;
    final pct = estimate.cost > 0 ? benefit / estimate.cost * 100 : 0.0;

    final (IconData icon, Color color, String text) = switch (health) {
      PriceHealth.good => (
        Icons.trending_up,
        AppColors.success,
        AppStrings.healthGood(formatEuro(benefit), pct),
      ),
      PriceHealth.low => (
        Icons.trending_flat,
        AppColors.warning,
        AppStrings.healthLow(
          formatEuro(estimate.suggestedPrice - price),
          formatEuro(benefit),
        ),
      ),
      PriceHealth.loss => (
        Icons.trending_down,
        AppColors.danger,
        AppStrings.healthLoss(formatEuro(-benefit)),
      ),
      PriceHealth.neutral => (
        Icons.info_outline,
        AppColors.textMuted,
        price <= 0 ? AppStrings.healthHint : '',
      ),
    };
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingLine extends StatelessWidget {
  const _PendingLine({required this.price, required this.paid});

  final double price;
  final double paid;

  @override
  Widget build(BuildContext context) {
    final pending = price - paid;
    final settled = price > 0 && pending <= 0;
    return Row(
      children: [
        Icon(
          settled ? Icons.check_circle : Icons.hourglass_top,
          size: 16,
          color: settled ? AppColors.success : AppColors.warning,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            settled
                ? AppStrings.fullyPaid
                : AppStrings.pendingToCollect(formatEuro(pending)),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: settled ? AppColors.success : AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }
}
