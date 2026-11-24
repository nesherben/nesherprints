import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        return Column(
          children: [
            if (wide)
              _HeaderRow(
                sortColumn: sortColumn,
                ascending: ascending,
                onSort: onSort,
              ),
            Expanded(
              child: ListView.separated(
                padding: wide
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(AppSpacing.md),
                itemCount: orders.length,
                separatorBuilder: (_, _) => wide
                    ? const Divider()
                    : const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => wide
                    ? _WideRow(order: orders[i], actions: actions)
                    : _CompactCard(order: orders[i], actions: actions),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== Cabecera ====================

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.sortColumn,
    required this.ascending,
    required this.onSort,
  });

  final OrderSortColumn sortColumn;
  final bool ascending;
  final ValueChanged<OrderSortColumn> onSort;

  Widget _label(
    String text,
    OrderSortColumn column, {
    TextAlign align = TextAlign.start,
  }) {
    final active = column == sortColumn;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => onSort(column),
      child: Padding(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _WideRow.idWidth,
            child: _label(AppStrings.colIdDate, OrderSortColumn.id),
          ),
          const SizedBox(width: _WideRow.gap),
          Expanded(
            flex: 3,
            child: _label(AppStrings.colProject, OrderSortColumn.name),
          ),
          const SizedBox(width: _WideRow.gap),
          SizedBox(
            width: _WideRow.statusWidth,
            child: _label(AppStrings.colStatus, OrderSortColumn.status),
          ),
          const SizedBox(width: _WideRow.gap),
          SizedBox(
            width: _WideRow.financeWidth,
            child: _label(
              AppStrings.colFinances,
              OrderSortColumn.price,
              align: TextAlign.end,
            ),
          ),
          const SizedBox(width: _WideRow.gap),
          const Expanded(
            flex: 2,
            child: Text(
              AppStrings.colDetailsUpper,
              style: AppTextStyles.overline,
            ),
          ),
          const SizedBox(width: _WideRow.gap),
          const SizedBox(width: _WideRow.actionsWidth),
        ],
      ),
    );
  }
}

// ==================== Fila ancha ====================

class _WideRow extends StatelessWidget {
  const _WideRow({required this.order, required this.actions});

  static const double idWidth = 84;
  static const double statusWidth = 140;
  static const double financeWidth = 168;
  static const double actionsWidth = 152;
  static const double gap = AppSpacing.md;

  final OrderSummary order;
  final OrderListActions actions;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => actions.onOpen(order),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: idWidth,
              child: _IdDate(order: order),
            ),
            const SizedBox(width: gap),
            Expanded(flex: 3, child: _Project(order: order)),
            const SizedBox(width: gap),
            SizedBox(
              width: statusWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  status: order.order.status,
                  onChanged: (s) => actions.onStatusChange(order, s),
                ),
              ),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: financeWidth,
              child: _Finance(order: order.order, alignEnd: true),
            ),
            const SizedBox(width: gap),
            Expanded(flex: 2, child: _Details(order: order)),
            const SizedBox(width: gap),
            SizedBox(
              width: actionsWidth,
              child: _Actions(order: order, actions: actions),
            ),
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

class _Finance extends StatelessWidget {
  const _Finance({required this.order, this.alignEnd = false});

  final Order order;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final settled = order.isSettled;
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlign = alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: rowAlign,
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
    final names = order.plateNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Mini(
              icon: Icons.layers_outlined,
              text: AppStrings.platesCount(order.platesCount),
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
          IconButton.filledTonal(
            tooltip: AppStrings.completeTooltip,
            icon: const Icon(Icons.check, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.success,
              backgroundColor: AppColors.success.withValues(alpha: 0.14),
            ),
            onPressed: () => actions.onComplete(order),
          ),
        IconButton(
          tooltip: status.isLocked
              ? AppStrings.viewAction
              : AppStrings.editAction,
          icon: Icon(
            status.isLocked ? Icons.visibility_outlined : Icons.edit_outlined,
            size: 20,
          ),
          onPressed: () => actions.onOpen(order),
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
