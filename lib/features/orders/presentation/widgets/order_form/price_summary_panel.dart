import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/section_header.dart';
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
    this.frozenCost,
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

  /// Coste congelado al completar el pedido (si ya está cerrado).
  final double? frozenCost;

  /// Pone el importe cobrado (los atajos 0 / 50 % / todo).
  final ValueChanged<double> onSetPaid;

  @override
  Widget build(BuildContext context) {
    final price = parseDecimal(priceController.text);
    final paid = parseDecimal(paidController.text);
    final health = PriceHealth.evaluate(price: price, estimate: estimate);
    final cost = (isLocked ? frozenCost : null) ?? estimate.cost;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppStrings.sectionCost,
          icon: Icons.calculate_outlined,
          meta: AppStrings.summaryMeta(
            plateCount,
            formatDuration(totalMinutes),
            totalGrams,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Breakdown(estimate: estimate, attempts: attempts, cost: cost),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(
          title: AppStrings.sectionPrice,
          icon: Icons.sell_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: priceController,
          readOnly: isLocked,
          keyboardType: decimalKeyboard,
          inputFormatters: decimalInputFormatters,
          onChanged: (_) => onPriceChanged(),
          style: AppTextStyles.kpiValue.copyWith(fontSize: 24),
          decoration: const InputDecoration(
            labelText: AppStrings.finalPriceLabel,
            prefixText: '€ ',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isLocked)
          _ProfitLine(price: price, cost: cost)
        else ...[
          _HealthMessage(health: health, price: price, estimate: estimate),
          const SizedBox(height: AppSpacing.sm),
          _Recommended(
            value: estimate.suggestedPrice,
            minimumApplied: estimate.minimumApplied,
            paintSurcharge: estimate.paintSurcharge,
            showApply: estimate.suggestedPrice > 0,
            onApply: onApplySuggested,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(
          title: AppStrings.sectionCollection,
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
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
  const _Breakdown({
    required this.estimate,
    required this.attempts,
    required this.cost,
  });

  final PriceEstimate estimate;
  final double attempts;

  /// Coste total mostrado (el congelado si el pedido ya está cerrado).
  final double cost;

  @override
  Widget build(BuildContext context) {
    final lines = <(String, double)>[
      (AppStrings.lineMaterial, estimate.materialCost),
      (AppStrings.lineMachine, estimate.machineCost),
      if (estimate.platesCost > 0) (AppStrings.linePlates, estimate.platesCost),
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
              Text(formatEuro(cost), style: AppTextStyles.money),
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
    required this.paintSurcharge,
    required this.showApply,
    required this.onApply,
  });

  final double value;
  final bool minimumApplied;

  /// Lo que suma la pintura al recomendado (0 si no se pinta).
  final double paintSurcharge;
  final bool showApply;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    const Text(
                      AppStrings.suggestedPrice,
                      style: AppTextStyles.mutedSmall,
                    ),
                    Text(
                      formatEuro(value),
                      style: AppTextStyles.kpiValue.copyWith(
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (minimumApplied)
                  const Text(
                    AppStrings.minimumNote,
                    style: AppTextStyles.mutedSmall,
                  ),
                if (paintSurcharge > 0)
                  Text(
                    AppStrings.paintSurchargeNote(formatEuro(paintSurcharge)),
                    style: AppTextStyles.mutedSmall,
                  ),
              ],
            ),
          ),
          if (showApply)
            FilledButton.tonal(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 34),
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

/// Beneficio real de un pedido cerrado: precio − coste congelado.
class _ProfitLine extends StatelessWidget {
  const _ProfitLine({required this.price, required this.cost});

  final double price;
  final double cost;

  @override
  Widget build(BuildContext context) {
    final profit = price - cost;
    final color = profit >= 0 ? AppColors.success : AppColors.danger;
    return Row(
      children: [
        Icon(
          profit >= 0 ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            AppStrings.realProfit(
              profit < 0 ? '-${formatEuro(-profit)}' : formatEuro(profit),
            ),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
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
    final overpaid = pending < -0.005;
    return Row(
      children: [
        Icon(
          overpaid
              ? Icons.error_outline
              : (settled ? Icons.check_circle : Icons.hourglass_top),
          size: 16,
          color: overpaid
              ? AppColors.danger
              : (settled ? AppColors.success : AppColors.warning),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            overpaid
                ? AppStrings.overpaid(formatEuro(-pending))
                : (settled
                      ? AppStrings.fullyPaid
                      : AppStrings.pendingToCollect(formatEuro(pending))),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: overpaid
                  ? AppColors.danger
                  : (settled ? AppColors.success : AppColors.warning),
            ),
          ),
        ),
      ],
    );
  }
}
