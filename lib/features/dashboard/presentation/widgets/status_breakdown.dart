import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/presentation/status_style.dart';

/// Reparto de pedidos por estado: una barra con la proporción de cada uno y
/// su leyenda con número y porcentaje.
class StatusBreakdown extends StatelessWidget {
  const StatusBreakdown({super.key, required this.counts, required this.total});

  final Map<OrderStatus, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final present = counts.entries.where((e) => e.value > 0).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.distributionTitle,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                Text('$total', style: AppTextStyles.money),
                const SizedBox(width: 4),
                const Text(
                  AppStrings.ordersWord,
                  style: AppTextStyles.mutedSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (total == 0)
              const Expanded(
                child: EmptyState(
                  icon: Icons.pie_chart_outline,
                  title: AppStrings.noData,
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, e) in present.indexed) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: e.value,
                          child: Tooltip(
                            message: AppStrings.statusLegend(
                              e.key.label,
                              e.value,
                            ),
                            child: ColoredBox(color: statusColor(e.key)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final e in present)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon(e.key),
                          size: 16,
                          color: statusColor(e.key),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${e.key.label} ${e.value} '
                          '(${formatPercent(e.value / total, decimals: 0)})',
                          style: AppTextStyles.muted,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
