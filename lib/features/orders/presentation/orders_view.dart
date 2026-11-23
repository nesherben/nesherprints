import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_data_table.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/order_form_dialog.dart';
import 'package:nesherprints/features/orders/presentation/widgets/waste_dialog.dart';

/// Registro de pedidos: búsqueda, filtro por estado, orden y acciones.
///
/// Los pedidos y las operaciones de escritura vienen de `MainLayout`.
class OrdersView extends StatefulWidget {
  const OrdersView({
    super.key,
    required this.orders,
    required this.onSave,
    required this.onStatusChange,
    required this.onComplete,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<OrderSummary> orders;
  final Future<void> Function(OrderFormResult result) onSave;
  final Future<void> Function(OrderSummary order, OrderStatus status)
  onStatusChange;
  final Future<void> Function(OrderSummary order) onComplete;
  final Future<void> Function(OrderSummary order) onDelete;
  final Future<void> Function() onRefresh;

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final _searchController = TextEditingController();

  /// `null` = todos los estados.
  OrderStatus? _statusFilter;
  OrderSortColumn? _sortColumn;
  bool _isAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _statusFilter != null ||
      _sortColumn != null;

  /// Pedidos tras aplicar búsqueda, filtro y orden.
  List<OrderSummary> get _visibleOrders {
    final query = _searchController.text.toLowerCase();
    final list = widget.orders.where((o) {
      final matchesSearch = o.order.name.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == null || o.order.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    if (_sortColumn == null) {
      list.sort((a, b) => b.id.compareTo(a.id));
      return list;
    }
    Comparable key(OrderSummary o) => switch (_sortColumn!) {
      OrderSortColumn.id => o.id,
      OrderSortColumn.name => o.order.name.toLowerCase(),
      OrderSortColumn.status => o.order.status.dbValue,
      OrderSortColumn.price => o.order.price,
    };
    list.sort(
      (a, b) => _isAscending
          ? Comparable.compare(key(a), key(b))
          : Comparable.compare(key(b), key(a)),
    );
    return list;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _statusFilter = null;
      _sortColumn = null;
      _isAscending = false;
    });
  }

  // ==================== ACCIONES ====================

  Future<void> _complete(OrderSummary order) async {
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.completeTitle,
      message: AppStrings.completeMessage,
      confirmText: AppStrings.completeConfirm,
      color: AppColors.success,
    );
    if (!ok) return;
    await widget.onComplete(order);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.orderCompleted)));
  }

  Future<void> _delete(OrderSummary order) async {
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.deleteOrderTitle,
      message: AppStrings.deleteOrderMessage,
      confirmText: AppStrings.delete,
      color: AppColors.dangerBright,
    );
    if (ok) await widget.onDelete(order);
  }

  void _edit(OrderSummary order) {
    showDialog(
      context: context,
      builder: (_) =>
          OrderFormDialog(initialOrder: order.order, onSave: widget.onSave),
    );
  }

  void _registerWaste(OrderSummary order) {
    showDialog(
      context: context,
      builder: (_) => WasteDialog(
        orderId: order.id,
        onSaved: () {
          widget.onRefresh();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.wasteRegistered),
              backgroundColor: AppColors.warning,
            ),
          );
        },
      ),
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: AppStrings.ordersTitle),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: OrderDataTable(
                orders: _visibleOrders,
                sortColumn: _sortColumn,
                isAscending: _isAscending,
                onSort: (column, ascending) => setState(() {
                  _sortColumn = column;
                  _isAscending = ascending;
                }),
                onStatusChange: widget.onStatusChange,
                onComplete: _complete,
                onEdit: _edit,
                onWaste: _registerWaste,
                onDelete: _delete,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: AppStrings.searchProject,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<OrderStatus?>(
            // La clave fuerza a mostrar "Todos" tras limpiar filtros.
            key: ValueKey(_statusFilter),
            initialValue: _statusFilter,
            decoration: const InputDecoration(
              labelText: AppStrings.filterByStatus,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text(AppStrings.all)),
              for (final s in OrderStatus.values)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (s) => setState(() => _statusFilter = s),
          ),
        ),
        const SizedBox(width: 16),
        if (_hasActiveFilters)
          ElevatedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text(AppStrings.clearFilters),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textMain,
            ),
          )
        else
          const SizedBox(width: 150),
      ],
    );
  }
}
