import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/monthly_revenue_chart.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/status_pie_chart.dart';
import 'package:nesherprints/features/orders/domain/order.dart';

/// Panel: KPIs de facturación, histórico mensual y distribución por estado.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.orders});

  final List<OrderSummary> orders;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  FinanceSummary? _summary;

  /// Evita que un cálculo antiguo pise a uno más reciente.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orders != oldWidget.orders) _calculate();
  }

  Future<void> _calculate() async {
    final generation = ++_generation;
    setState(() => _summary = null);

    final materials = await ServiceLocator.materials.getAll();
    final legacyItems = await ServiceLocator.orders.getLegacyItems();
    final waste = await ServiceLocator.orders.getAllWaste();
    if (!mounted || generation != _generation) return;

    setState(() {
      _summary = FinanceSummary.compute(
        orders: widget.orders,
        materialCostPerKg: {for (final m in materials) m.id!: m.costPerKg},
        legacyItems: legacyItems,
        waste: waste,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: AppStrings.billingHistoryTitle,
            subtitle: AppStrings.dashboardSubtitle,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: AppStrings.kpiGrossRevenue,
                  value: formatEuro(summary.grossRevenue),
                  icon: Icons.account_balance_wallet,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: AppStrings.kpiNetProfit,
                  value: formatEuro(summary.netProfit),
                  icon: Icons.savings,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: AppStrings.kpiPendingCollection,
                  value: formatEuro(summary.pendingCollection),
                  icon: Icons.hourglass_top,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: MonthlyRevenueChart(
                    monthly: summary.monthly,
                    hasRevenue: summary.grossRevenue > 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatusPieChart(
                    counts: summary.statusCounts,
                    total: summary.totalOrders,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
