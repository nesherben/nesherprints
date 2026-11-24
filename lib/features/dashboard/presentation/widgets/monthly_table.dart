import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';

/// Detalle por mes: pedidos, facturado, beneficio real y margen (como las
/// columnas `AC`, `AE` y `AF` del Excel). El mes más reciente va primero.
class MonthlyTable extends StatelessWidget {
  const MonthlyTable({super.key, required this.monthly});

  final Map<String, MonthStats> monthly;

  @override
  Widget build(BuildContext context) {
    final months = monthly.keys.toList().reversed.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.monthlyDetailTitle,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            const _Row(
              cells: [
                AppStrings.colMonth,
                AppStrings.colOrders,
                AppStrings.colGross,
                AppStrings.colProfit,
                AppStrings.colMargin,
              ],
              header: true,
            ),
            const Divider(),
            Expanded(
              child: months.isEmpty
                  ? const EmptyState(
                      icon: Icons.table_rows_outlined,
                      title: AppStrings.noData,
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: months.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (_, i) {
                        final stats = monthly[months[i]]!;
                        return _Row(
                          cells: [
                            formatMonth(months[i]),
                            '${stats.orders}',
                            formatEuro(stats.gross),
                            formatEuro(stats.profit),
                            formatPercent(stats.ratio),
                          ],
                          profitPositive: stats.profit >= 0,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.cells,
    this.header = false,
    this.profitPositive = true,
  });

  final List<String> cells;
  final bool header;
  final bool profitPositive;

  @override
  Widget build(BuildContext context) {
    TextStyle style(int column) {
      if (header) return AppTextStyles.overline;
      return switch (column) {
        0 => const TextStyle(fontWeight: FontWeight.w600),
        3 => AppTextStyles.money.copyWith(
          color: profitPositive ? AppColors.success : AppColors.danger,
        ),
        _ => AppTextStyles.money.copyWith(fontWeight: FontWeight.w500),
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (final (i, text) in cells.indexed)
            Expanded(
              flex: switch (i) {
                0 => 5,
                1 => 4,
                4 => 4,
                _ => 5,
              },
              child: Text(
                header ? text.toUpperCase() : text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: i == 0 ? TextAlign.start : TextAlign.end,
                style: style(i),
              ),
            ),
        ],
      ),
    );
  }
}
