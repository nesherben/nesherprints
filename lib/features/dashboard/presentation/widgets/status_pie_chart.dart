import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/presentation/status_style.dart';

/// Gráfico de anillo con el % de pedidos por estado y su leyenda.
class StatusPieChart extends StatelessWidget {
  const StatusPieChart({super.key, required this.counts, required this.total});

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
            const Text(
              AppStrings.distributionTitle,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: total == 0
                  ? const EmptyState(
                      icon: Icons.pie_chart_outline,
                      title: AppStrings.noData,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 54,
                            sections: [
                              for (final e in present)
                                PieChartSectionData(
                                  color: statusColor(e.key),
                                  value: e.value.toDouble(),
                                  showTitle: false,
                                  radius: 22,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$total', style: AppTextStyles.kpiValue),
                            const Text(
                              AppStrings.ordersWord,
                              style: AppTextStyles.mutedSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                for (final e in present)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor(e.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.statusLegend(e.key.label, e.value),
                        style: AppTextStyles.mutedSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
