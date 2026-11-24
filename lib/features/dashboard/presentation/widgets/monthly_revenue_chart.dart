import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';

/// Barras de facturado y beneficio real por mes. Con muchos meses la gráfica
/// se desplaza horizontalmente.
class MonthlyRevenueChart extends StatelessWidget {
  const MonthlyRevenueChart({super.key, required this.monthly});

  /// Ordenado cronológicamente.
  final Map<String, MonthStats> monthly;

  /// Ancho mínimo de cada mes.
  static const double _monthWidth = 76;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.monthlyChartTitle,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                _Legend(color: AppColors.primary, label: AppStrings.grossLabel),
                SizedBox(width: AppSpacing.md),
                _Legend(color: AppColors.success, label: AppStrings.netLabel),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: monthly.isEmpty
                  ? const EmptyState(
                      icon: Icons.bar_chart,
                      title: AppStrings.noData,
                      message: AppStrings.completeFirstOrderHint,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (monthly.length * _monthWidth)
                            .clamp(constraints.maxWidth, double.infinity)
                            .toDouble();
                        final chart = SizedBox(
                          width: width,
                          child: BarChart(_data()),
                        );
                        return width > constraints.maxWidth
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                child: chart,
                              )
                            : chart;
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _data() {
    final months = monthly.keys.toList();
    BarChartRodData rod(double value, Color color) => BarChartRodData(
      toY: value,
      color: color,
      width: 14,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    );

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.secondary,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final stats = monthly[months[group.x]]!;
            return BarTooltipItem(
              rodIndex == 0
                  ? AppStrings.chartTooltipGross(
                      formatMonth(months[group.x]),
                      formatEuro(stats.gross),
                    )
                  : AppStrings.chartTooltipProfit(
                      formatEuro(stats.profit),
                      formatPercent(stats.ratio),
                    ),
              const TextStyle(
                color: AppColors.textMain,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= months.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(
                  formatMonth(months[index]),
                  style: AppTextStyles.mutedSmall,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child: Text(
                formatEuroCompact(value),
                style: AppTextStyles.mutedSmall,
              ),
            ),
          ),
        ),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (var i = 0; i < months.length; i++)
          BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              rod(monthly[months[i]]!.gross, AppColors.primary),
              rod(monthly[months[i]]!.profit, AppColors.success),
            ],
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.mutedSmall),
      ],
    );
  }
}
