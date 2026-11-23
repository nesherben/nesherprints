import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';

/// Barras de bruto y neto por mes.
class MonthlyRevenueChart extends StatelessWidget {
  const MonthlyRevenueChart({
    super.key,
    required this.monthly,
    required this.hasRevenue,
  });

  /// Ordenado cronológicamente.
  final Map<String, MonthlyFinance> monthly;
  final bool hasRevenue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.billingHistoryTitle,
                  style: AppTextStyles.cardTitle,
                ),
                Row(
                  children: [
                    _LegendSquare(color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(AppStrings.grossLabel, style: TextStyle(fontSize: 12)),
                    SizedBox(width: 12),
                    _LegendSquare(color: AppColors.success),
                    SizedBox(width: 4),
                    Text(AppStrings.netLabel, style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: monthly.isEmpty
                  ? const Center(child: Text(AppStrings.completeFirstOrderHint))
                  : BarChart(_chartData()),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _chartData() {
    final months = monthly.keys.toList();
    BarChartRodData rod(double value, Color color) => BarChartRodData(
      toY: value,
      color: color,
      width: 16,
      borderRadius: BorderRadius.circular(4),
    );

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: hasRevenue ? null : 100,
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= months.length) return const Text('');
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  months[index],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      gridData: const FlGridData(drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (var i = 0; i < months.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              rod(monthly[months[i]]!.gross, AppColors.primary),
              rod(monthly[months[i]]!.net, AppColors.success),
            ],
          ),
      ],
    );
  }
}

class _LegendSquare extends StatelessWidget {
  const _LegendSquare({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.square, color: color, size: 12);
}
