import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/presentation/widgets/status_badge.dart';

/// Columnas ordenables de la tabla (índice = posición de la columna).
enum OrderSortColumn { id, name, status, price }

/// Tabla de pedidos. Solo pinta y avisa de acciones; no accede a datos.
class OrderDataTable extends StatelessWidget {
  const OrderDataTable({
    super.key,
    required this.orders,
    required this.sortColumn,
    required this.isAscending,
    required this.onSort,
    required this.onStatusChange,
    required this.onComplete,
    required this.onEdit,
    required this.onWaste,
    required this.onDelete,
  });

  final List<OrderSummary> orders;
  final OrderSortColumn? sortColumn;
  final bool isAscending;
  final void Function(OrderSortColumn column, bool ascending) onSort;
  final void Function(OrderSummary order, OrderStatus status) onStatusChange;
  final ValueChanged<OrderSummary> onComplete;
  final ValueChanged<OrderSummary> onEdit;
  final ValueChanged<OrderSummary> onWaste;
  final ValueChanged<OrderSummary> onDelete;

  DataColumn _sortable(
    String label,
    OrderSortColumn column, {
    bool numeric = false,
  }) => DataColumn(
    label: Text(label),
    numeric: numeric,
    onSort: (_, ascending) => onSort(column, ascending),
  );

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text(AppStrings.noOrdersForFilters));
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          sortColumnIndex: sortColumn?.index,
          sortAscending: isAscending,
          dataRowMaxHeight: 70,
          headingTextStyle: AppTextStyles.tableHeading,
          columns: [
            _sortable(AppStrings.colIdDate, OrderSortColumn.id),
            _sortable(AppStrings.colProject, OrderSortColumn.name),
            _sortable(AppStrings.colStatus, OrderSortColumn.status),
            _sortable(
              AppStrings.colFinances,
              OrderSortColumn.price,
              numeric: true,
            ),
            const DataColumn(label: Text(AppStrings.colDetails)),
            const DataColumn(label: Text(AppStrings.colActions)),
          ],
          rows: [
            for (final o in orders)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      '#${o.id}\n${o.order.date}',
                      style: AppTextStyles.mutedSmall,
                    ),
                  ),
                  DataCell(_ProjectCell(order: o)),
                  DataCell(
                    StatusBadge(
                      status: o.order.status,
                      onChanged: (s) => onStatusChange(o, s),
                    ),
                  ),
                  DataCell(_FinanceCell(order: o.order)),
                  DataCell(_DetailsCell(order: o)),
                  DataCell(_actions(o)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _actions(OrderSummary o) {
    return Row(
      children: [
        if (o.order.status.canComplete)
          IconButton(
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 20,
            ),
            tooltip: AppStrings.completeTooltip,
            onPressed: () => onComplete(o),
          ),
        IconButton(
          icon: const Icon(
            Icons.edit_outlined,
            color: AppColors.info,
            size: 20,
          ),
          onPressed: () => onEdit(o),
        ),
        IconButton(
          icon: const Icon(Icons.recycling, color: AppColors.warning, size: 20),
          tooltip: AppStrings.wasteTooltip,
          onPressed: () => onWaste(o),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: AppColors.danger,
            size: 20,
          ),
          onPressed: () => onDelete(o),
        ),
      ],
    );
  }
}

class _ProjectCell extends StatelessWidget {
  const _ProjectCell({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.order.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        if (order.clientName != null)
          Text(
            '👤 ${order.clientName}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

class _FinanceCell extends StatelessWidget {
  const _FinanceCell({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final settled = order.isSettled;
    final pending = order.pendingAmount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: settled
            ? AppColors.success.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.orderTotal(formatEuro(order.price)),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: settled ? AppColors.success : AppColors.primary,
                ),
              ),
              if (settled) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 14,
                ),
              ],
            ],
          ),
          Text(
            AppStrings.orderPaid(formatEuro(order.paidAmount)),
            style: const TextStyle(color: AppColors.success, fontSize: 12),
          ),
          if (pending > 0)
            Text(
              AppStrings.orderPending(formatEuro(pending)),
              style: const TextStyle(
                color: AppColors.dangerBright,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailsCell extends StatelessWidget {
  const _DetailsCell({required this.order});

  final OrderSummary order;

  static Color _wasteColor(WasteSeverity severity) => switch (severity) {
    WasteSeverity.high => AppColors.danger,
    WasteSeverity.medium => AppColors.warning,
    WasteSeverity.low => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final wasteColor = _wasteColor(order.wasteSeverity);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.order.isPainted)
          const Row(
            children: [
              Icon(Icons.brush, size: 12, color: AppColors.info),
              SizedBox(width: 4),
              Text(AppStrings.painted, style: TextStyle(fontSize: 11)),
            ],
          ),
        Row(
          children: [
            const Icon(Icons.layers, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              AppStrings.platesCount(order.platesCount),
              style: const TextStyle(fontSize: 11),
            ),
            if (order.wastedGrams > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: wasteColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AppStrings.wastePercent(order.wasteRatePercent),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: wasteColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (order.plateNames?.isNotEmpty ?? false)
          Text(
            order.plateNames!,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
