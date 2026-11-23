import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Tarta con el % de pedidos por estado y su leyenda.
class StatusPieChart extends StatelessWidget {
  const StatusPieChart({super.key, required this.counts, required this.total});

  final Map<OrderStatus, int> counts;
  final int total;

  static Color colorFor(OrderStatus status) => switch (status) {
    OrderStatus.completed || OrderStatus.shipped => AppColors.success,
    OrderStatus.inProgress => AppColors.primary,
    OrderStatus.reserved => AppColors.info,
    OrderStatus.canceled => AppColors.danger,
    OrderStatus.draft => AppColors.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final present = counts.entries.where((e) => e.value > 0).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              AppStrings.distributionTitle,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: total == 0
                  ? const Center(child: Text(AppStrings.noData))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          for (final e in present)
                            PieChartSectionData(
                              color: colorFor(e.key),
                              value: e.value.toDouble(),
                              title:
                                  '${(e.value / total * 100).toStringAsFixed(0)}%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onAccent,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final e in present)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorFor(e.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.statusLegend(e.key.label, e.value),
                        style: const TextStyle(fontSize: 12),
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
