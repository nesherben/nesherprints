import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/section_header.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/presentation/status_style.dart';
import 'package:nesherprints/features/orders/presentation/widgets/status_badge.dart';

/// Columnas por las que se puede ordenar el listado.
enum OrderSortColumn { id, date, name, status, price, pending }

/// Acciones de la fila disponibles en el menú «más».
enum OrderMenuAction { waste, duplicate, delete }

/// Callbacks que el listado lanza; no accede a datos.
class OrderListActions {
  const OrderListActions({
    required this.onOpen,
    required this.onStatusChange,
    required this.onComplete,
    required this.onMenu,
  });

  final ValueChanged<OrderSummary> onOpen;
  final void Function(OrderSummary order, OrderStatus status) onStatusChange;
  final ValueChanged<OrderSummary> onComplete;
  final void Function(OrderSummary order, OrderMenuAction action) onMenu;
}

/// Listado de pedidos, virtualizado: en ventana ancha filas con columnas y
/// cabecera ordenable; en estrecha, tarjetas apiladas.
class OrderList extends StatelessWidget {
  const OrderList({
    super.key,
    required this.orders,
    required this.sortColumn,
    required this.ascending,
    required this.onSort,
    required this.actions,
  });

  /// Anchura mínima del contenedor para usar filas con columnas.
  static const double wideBreakpoint = 880;

  final List<OrderSummary> orders;
  final OrderSortColumn sortColumn;
  final bool ascending;
  final ValueChanged<OrderSortColumn> onSort;
  final OrderListActions actions;

  /// Los pedidos con una cabecera de mes delante de cada grupo (solo cuando se
  /// ordena por ID o fecha; con otro orden los meses saldrían mezclados).
  List<Object> _entries() {
    final byMonth =
        sortColumn == OrderSortColumn.id || sortColumn == OrderSortColumn.date;
    if (!byMonth) return orders;
    final entries = <Object>[];
    _MonthGroup? current;
    for (final summary in orders) {
      final date = summary.order.date;
      final key = date.length >= 7 ? date.substring(0, 7) : '';
      if (current == null || current.key != key) {
        current = _MonthGroup(key);
        entries.add(current);
      }
      current.count++;
      if (summary.order.status.countsAsRevenue) {
        current.billed += summary.order.price;
      }
      entries.add(summary);
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        final roomy = constraints.maxWidth >= _WideRow.roomyBreakpoint;
        return Column(
          children: [
            if (wide)
              _HeaderRow(
                roomy: roomy,
                sortColumn: sortColumn,
                ascending: ascending,
                onSort: onSort,
              ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final entries = _entries();
                  return ListView.builder(
                    padding: wide
                        ? EdgeInsets.zero
                        : const EdgeInsets.all(AppSpacing.md),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final entry = entries[i];
                      if (entry is _MonthGroup) {
                        return _MonthHeader(group: entry, wide: wide);
                      }
                      final order = entry as OrderSummary;
                      if (wide) {
                        // Línea divisoria salvo bajo una cabecera de mes.
                        final first = i > 0 && entries[i - 1] is _MonthGroup;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (i > 0 && !first) const Divider(),
                            _WideRow(
                              order: order,
                              actions: actions,
                              roomy: roomy,
                            ),
                          ],
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _CompactCard(order: order, actions: actions),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== Cabeceras de mes ====================

/// Pedidos de un mes: clave `yyyy-MM`, cuántos son y cuánto se facturó.
class _MonthGroup {
  _MonthGroup(this.key);

  final String key;
  int count = 0;
  double billed = 0;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.group, required this.wide});

  final _MonthGroup group;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final title = group.key.isEmpty
        ? AppStrings.noDate
        : formatMonth(group.key);
    final meta = group.billed > 0
        ? AppStrings.monthGroupMeta(group.count, formatEuro(group.billed))
        : AppStrings.ordersCount(group.count);
    return Container(
      color: AppColors.surfaceHigh.withValues(alpha: 0.35),
      padding: EdgeInsets.fromLTRB(
        wide ? AppSpacing.lg : AppSpacing.md,
        AppSpacing.sm,
        wide ? AppSpacing.lg : AppSpacing.md,
        AppSpacing.sm,
      ),
      margin: wide ? null : const EdgeInsets.only(bottom: AppSpacing.md),
      child: SectionHeader(
        title: title,
        icon: Icons.calendar_month_outlined,
        meta: meta,
      ),
    );
  }
}

// ==================== Cabecera ====================

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.roomy,
    required this.sortColumn,
    required this.ascending,
    required this.onSort,
  });

  final bool roomy;
  final OrderSortColumn sortColumn;
  final bool ascending;
  final ValueChanged<OrderSortColumn> onSort;

  Widget _label(
    String text,
    OrderSortColumn? column, {
    TextAlign align = TextAlign.start,
  }) {
    final active = column != null && column == sortColumn;
    final label = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: align == TextAlign.end
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              text.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.overline.copyWith(
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          if (active)
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 13,
              color: AppColors.primary,
            ),
        ],
      ),
    );
    if (column == null) return label;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => onSort(column),
      child: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: _WideRow.gap);
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.only(
        left: AppSpacing.lg + _WideRow.accentWidth,
        right: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.lg - AppSpacing.lg),
          SizedBox(
            width: _WideRow.idWidth,
            child: _label(AppStrings.colId, OrderSortColumn.id),
          ),
          gap,
          SizedBox(
            width: _WideRow.dateWidth,
            child: _label(AppStrings.colDate, OrderSortColumn.date),
          ),
          gap,
          Expanded(child: _label(AppStrings.colProject, OrderSortColumn.name)),
          if (roomy) ...[
            gap,
            SizedBox(
              width: _WideRow.clientWidth,
              child: _label(AppStrings.colClient, null),
            ),
          ],
          gap,
          SizedBox(
            width: _WideRow.statusWidth,
            child: _label(AppStrings.colStatus, OrderSortColumn.status),
          ),
          gap,
          SizedBox(
            width: _WideRow.priceWidth,
            child: _label(
              AppStrings.colPrice,
              OrderSortColumn.price,
              align: TextAlign.end,
            ),
          ),
          gap,
          SizedBox(
            width: _WideRow.collectWidth,
            child: _label(AppStrings.colCollection, OrderSortColumn.pending),
          ),
          if (roomy) ...[
            gap,
            SizedBox(
              width: _WideRow.profitWidth,
              child: _label(AppStrings.colProfit, null, align: TextAlign.end),
            ),
          ],
          gap,
          const SizedBox(width: _WideRow.actionsWidth),
        ],
      ),
    );
  }
}

// ==================== Fila ancha ====================

class _WideRow extends StatelessWidget {
  const _WideRow({
    required this.order,
    required this.actions,
    required this.roomy,
  });

  static const double accentWidth = 3;
  static const double idWidth = 48;
  static const double dateWidth = 84;
  static const double clientWidth = 150;
  static const double statusWidth = 150;
  static const double priceWidth = 96;
  static const double collectWidth = 120;
  static const double profitWidth = 92;
  static const double actionsWidth = 96;
  static const double gap = AppSpacing.md;

  /// Anchura del listado a partir de la cual caben cliente y beneficio.
  static const double roomyBreakpoint = 1120;

  final OrderSummary order;
  final OrderListActions actions;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    const gapBox = SizedBox(width: gap);
    final o = order.order;
    return InkWell(
      onTap: () => actions.onOpen(order),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Franja con el color del estado: se ve de un vistazo.
            Container(width: accentWidth, color: statusColor(o.status)),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
              width: idWidth,
              child: Text(
                '#${order.id}',
                style: AppTextStyles.money.copyWith(color: AppColors.textMuted),
              ),
            ),
            gapBox,
            SizedBox(
              width: dateWidth,
              child: Text(
                o.date.isEmpty ? '—' : o.date,
                style: AppTextStyles.mutedSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            gapBox,
            Expanded(child: _ProjectInline(order: order)),
            if (roomy) ...[
              gapBox,
              SizedBox(
                width: clientWidth,
                child: Text(
                  order.clientName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.muted,
                ),
              ),
            ],
            gapBox,
            SizedBox(
              width: statusWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  status: o.status,
                  onChanged: (s) => actions.onStatusChange(order, s),
                ),
              ),
            ),
            gapBox,
            SizedBox(
              width: priceWidth,
              child: _Price(order: o),
            ),
            gapBox,
            SizedBox(
              width: collectWidth,
              child: _Collection(order: o),
            ),
            if (roomy) ...[
              gapBox,
              SizedBox(
                width: profitWidth,
                child: _ProfitText(order: order, alignEnd: true),
              ),
            ],
            gapBox,
            SizedBox(
              width: actionsWidth,
              child: _Actions(order: order, actions: actions),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ==================== Tarjeta estrecha ====================

class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.order, required this.actions});

  final OrderSummary order;
  final OrderListActions actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => actions.onOpen(order),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _Project(order: order)),
                  const SizedBox(width: AppSpacing.sm),
                  StatusBadge(
                    status: order.order.status,
                    onChanged: (s) => actions.onStatusChange(order, s),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _IdDate(order: order, inline: true),
              const SizedBox(height: AppSpacing.sm),
              _Details(order: order),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: _Finance(order: order.order)),
                  _Actions(order: order, actions: actions),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Celdas ====================

class _IdDate extends StatelessWidget {
  const _IdDate({required this.order, this.inline = false});

  final OrderSummary order;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final id = Text(
      '#${order.id}',
      style: AppTextStyles.money.copyWith(color: AppColors.textMuted),
    );
    final date = Text(
      order.order.date.isEmpty ? '—' : order.order.date,
      style: AppTextStyles.mutedSmall,
      overflow: TextOverflow.ellipsis,
    );
    if (inline) {
      return Row(
        children: [
          id,
          const SizedBox(width: AppSpacing.sm),
          date,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [id, date],
    );
  }
}

class _Project extends StatelessWidget {
  const _Project({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          order.order.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        if (order.clientName != null)
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  order.clientName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.mutedSmall,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Nombre del proyecto con sus datos (placas, pintura, merma) en la misma
/// línea; así la fila mide una sola línea.
class _ProjectInline extends StatelessWidget {
  const _ProjectInline({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final imported = order.plateNames?.startsWith('Importado') ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Flexible(
            child: Text(
              order.order.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          if (!imported && order.platesCount > 0) ...[
            const SizedBox(width: AppSpacing.md),
            _Mini(
              icon: Icons.layers_outlined,
              text: AppStrings.platesCount(order.platesCount),
            ),
          ],
          if (order.order.isPainted) ...[
            const SizedBox(width: AppSpacing.sm),
            const _Mini(
              icon: Icons.brush_outlined,
              text: AppStrings.painted,
              color: AppColors.info,
            ),
          ],
          if (order.wastedGrams > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            StatusPill(
              label: AppStrings.wastePercent(order.wasteRatePercent),
              color: _Details._wasteColor(order.wasteSeverity),
            ),
          ],
        ],
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final settled = order.isSettled;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (settled) ...[
          const Icon(Icons.check_circle, size: 15, color: AppColors.success),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            formatEuro(order.price),
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.money.copyWith(
              fontSize: 15,
              color: settled ? AppColors.success : AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }
}

class _Collection extends StatelessWidget {
  const _Collection({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    if (order.isSettled) {
      return const Text(
        AppStrings.collected,
        style: TextStyle(fontSize: 12, color: AppColors.success),
      );
    }
    return Tooltip(
      message: AppStrings.paidOfPending(
        formatEuro(order.paidAmount),
        formatEuro(order.pendingAmount),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.hourglass_bottom,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              AppStrings.pendingShort(formatEuro(order.pendingAmount)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Beneficio de un pedido cerrado (precio − coste congelado); «—» si no hay.
class _ProfitText extends StatelessWidget {
  const _ProfitText({required this.order, this.alignEnd = false});

  final OrderSummary order;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final o = order.order;
    final cost = o.costOverride;
    if (!o.status.countsAsRevenue || cost == null) {
      return Text(
        '—',
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: AppTextStyles.mutedSmall,
      );
    }
    final profit = o.price - cost;
    return Text(
      profit < 0 ? '-${formatEuro(-profit)}' : formatEuro(profit),
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: AppTextStyles.money.copyWith(
        fontSize: 14,
        color: profit >= 0 ? AppColors.success : AppColors.danger,
      ),
    );
  }
}

class _Finance extends StatelessWidget {
  const _Finance({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final settled = order.isSettled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (settled) ...[
              const Icon(
                Icons.check_circle,
                size: 15,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                formatEuro(order.price),
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.money.copyWith(
                  fontSize: 15,
                  color: settled ? AppColors.success : AppColors.textMain,
                ),
              ),
            ),
          ],
        ),
        if (settled)
          const Text(
            AppStrings.collected,
            style: TextStyle(fontSize: 12, color: AppColors.success),
          )
        else
          Text(
            AppStrings.paidOfPending(
              formatEuro(order.paidAmount),
              formatEuro(order.pendingAmount),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.order});

  final OrderSummary order;

  static Color _wasteColor(WasteSeverity s) => switch (s) {
    WasteSeverity.high => AppColors.danger,
    WasteSeverity.medium => AppColors.warning,
    WasteSeverity.low => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    // Los pedidos importados tienen una placa «Importado»: no aporta nada.
    final imported = order.plateNames?.startsWith('Importado') ?? false;
    final names = imported ? null : order.plateNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!imported)
              _Mini(
                icon: Icons.layers_outlined,
                text: AppStrings.platesCount(order.platesCount),
              ),
            if (order.order.status.countsAsRevenue &&
                order.order.costOverride != null)
              _Mini(
                icon: Icons.trending_up,
                text: AppStrings.profitOf(() {
                  final profit = order.order.price - order.order.costOverride!;
                  return profit < 0
                      ? '-${formatEuro(-profit)}'
                      : formatEuro(profit);
                }()),
                color: order.order.price >= order.order.costOverride!
                    ? AppColors.success
                    : AppColors.danger,
              ),
            if (order.order.isPainted)
              const _Mini(
                icon: Icons.brush_outlined,
                text: AppStrings.painted,
                color: AppColors.info,
              ),
            if (order.wastedGrams > 0)
              StatusPill(
                label: AppStrings.wastePercent(order.wasteRatePercent),
                color: _wasteColor(order.wasteSeverity),
              ),
          ],
        ),
        if (names != null && names.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              names,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.mutedSmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({
    required this.icon,
    required this.text,
    this.color = AppColors.textMuted,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.actions});

  final OrderSummary order;
  final OrderListActions actions;

  @override
  Widget build(BuildContext context) {
    final status = order.order.status;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (status.canComplete)
          IconButton(
            tooltip: AppStrings.completeTooltip,
            icon: const Icon(Icons.check_circle_outline, size: 22),
            color: AppColors.success,
            visualDensity: VisualDensity.compact,
            onPressed: () => actions.onComplete(order),
          ),
        PopupMenuButton<OrderMenuAction>(
          tooltip: AppStrings.moreActions,
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (a) => actions.onMenu(order, a),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: OrderMenuAction.waste,
              child: _MenuRow(
                icon: Icons.recycling,
                text: AppStrings.wasteAction,
                color: AppColors.warning,
              ),
            ),
            PopupMenuItem(
              value: OrderMenuAction.duplicate,
              child: _MenuRow(
                icon: Icons.copy_outlined,
                text: AppStrings.duplicateAction,
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: OrderMenuAction.delete,
              child: _MenuRow(
                icon: Icons.delete_outline,
                text: AppStrings.deleteAction,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.text,
    this.color = AppColors.textMain,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}
