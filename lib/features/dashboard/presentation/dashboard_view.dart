import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/monthly_revenue_chart.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/monthly_table.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/pending_list.dart';
import 'package:nesherprints/features/dashboard/presentation/widgets/status_breakdown.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_costing.dart';

/// Panel: indicadores del negocio, objetivo, histórico mensual, reparto por
/// estado y cobros pendientes.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.orders});

  final List<OrderSummary> orders;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  FinanceSummary? _summary;
  Object? _error;

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
    try {
      final settings = await ServiceLocator.settings.getPricingSettings();
      final materials = await ServiceLocator.materials.getAll();
      final plates = await ServiceLocator.orders.getPlatesByOrder();
      final extraLines = await ServiceLocator.orders.getExtraLinesByOrder();
      final waste = await ServiceLocator.orders.getAllWaste();
      if (!mounted || generation != _generation) return;

      final costPerKg = {for (final m in materials) m.id!: m.costPerKg};
      final costs = {
        for (final o in widget.orders)
          if (o.order.status.countsAsRevenue)
            o.id: OrderCosting.of(
              order: o.order,
              plates: plates[o.id] ?? const [],
              extras: extraLines[o.id] ?? const [],
              materialCostPerKg: costPerKg,
              settings: settings,
            ),
      };
      setState(() {
        _error = null;
        _summary = FinanceSummary.compute(
          orders: widget.orders,
          costs: costs,
          materialCostPerKg: {for (final m in materials) m.id!: m.costPerKg},
          waste: waste,
          profitGoal: settings.profitGoal,
        );
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = e);
      AppFeedback.failure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (summary == null) {
      if (_error != null) {
        return EmptyState(
          icon: Icons.error_outline,
          title: AppStrings.loadErrorTitle,
          message: AppFeedback.describe(_error!),
          action: ElevatedButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(AppStrings.retry),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final compact = context.isCompact;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: AppStrings.dashboardTitle,
            subtitle: AppStrings.dashboardSubtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          _KpiGrid(summary: summary),
          const SizedBox(height: AppSpacing.lg),
          _Panels(
            height: 360,
            left: MonthlyRevenueChart(monthly: summary.monthly),
            right: MonthlyTable(monthly: summary.monthly),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Panels(
            height: 150,
            left: StatusBreakdown(
              counts: summary.statusCounts,
              total: summary.totalOrders,
            ),
            right: PendingList(
              pending: summary.pendingOrders,
              total: summary.pendingCollection,
            ),
          ),
          if (summary.wasteRecords > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            _WasteNote(summary: summary),
          ],
          if (summary.personalOrders > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            _InfoNote(
              icon: Icons.person_outline,
              color: AppColors.info,
              text: AppStrings.personalNote(
                summary.personalOrders,
                formatEuro(summary.personalCost),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Indicadores principales: 4 en una fila, 2×2 o apilados según el ancho.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final goalReached = summary.goalProgress >= 1;
    List<KpiCard> buildCards({required bool narrow}) => [
      KpiCard(
        narrow: narrow,
        title: AppStrings.kpiGrossRevenue,
        value: formatEuro(summary.grossRevenue),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
        subtitle: AppStrings.completedOrdersCount(summary.completedOrders),
      ),
      KpiCard(
        narrow: narrow,
        title: AppStrings.kpiNetProfit,
        value: formatEuro(summary.profit),
        icon: Icons.savings_outlined,
        color: summary.profit >= 0 ? AppColors.success : AppColors.danger,
        subtitle: AppStrings.marginOnRevenue(
          formatPercent(summary.ratio, decimals: 1),
        ),
      ),
      KpiCard(
        narrow: narrow,
        title: AppStrings.kpiPendingCollection,
        value: formatEuro(summary.pendingCollection),
        icon: Icons.hourglass_top,
        color: summary.pendingCollection > 0
            ? AppColors.warning
            : AppColors.success,
        subtitle: AppStrings.pendingOrdersCount(summary.pendingOrders.length),
      ),
      KpiCard(
        narrow: narrow,
        title: AppStrings.kpiGoal,
        value: formatPercent(summary.goalProgress),
        icon: goalReached ? Icons.emoji_events_outlined : Icons.flag_outlined,
        color: goalReached ? AppColors.success : AppColors.info,
        progress: summary.goalProgress,
        subtitle: AppStrings.goalOf(
          formatEuro(summary.profit, decimals: 0),
          formatEuro(summary.profitGoal, decimals: 0),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;
        final cards = buildCards(narrow: narrow);
        final columns = constraints.maxWidth >= 1000 ? 4 : 2;
        // Más junto en móvil.
        final gap = narrow ? AppSpacing.md : AppSpacing.lg;
        // Filas de [columns] tarjetas con la misma altura (la del texto más
        // largo), para que no queden desiguales.
        return Column(
          children: [
            for (var start = 0; start < cards.length; start += columns) ...[
              if (start > 0) SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      Expanded(
                        child: start + i < cards.length
                            ? cards[start + i]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Dos paneles lado a lado (3:2) o apilados en ventana estrecha.
class _Panels extends StatelessWidget {
  const _Panels({
    required this.left,
    required this.right,
    required this.height,
  });

  final Widget left;
  final Widget right;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          // Apilados necesitan más alto: la leyenda y las listas se envuelven.
          final stackedHeight = height < 300 ? 300.0 : height;
          return Column(
            children: [
              SizedBox(height: stackedHeight, child: left),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(height: stackedHeight, child: right),
            ],
          );
        }
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: left),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 2, child: right),
            ],
          ),
        );
      },
    );
  }
}

class _WasteNote extends StatelessWidget {
  const _WasteNote({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.recycling, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppStrings.wasteNote(
                summary.wasteRecords,
                summary.wasteGrams,
                formatEuro(summary.wasteCost),
              ),
              style: const TextStyle(color: AppColors.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso informativo de una línea con icono.
class _InfoNote extends StatelessWidget {
  const _InfoNote({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
