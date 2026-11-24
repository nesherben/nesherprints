import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/domain/stock_check.dart';
import 'package:nesherprints/features/orders/presentation/status_style.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/order_form_dialog.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_list.dart';
import 'package:nesherprints/features/orders/presentation/widgets/waste_dialog.dart';

/// Registro de pedidos: búsqueda, filtros por estado, orden y acciones.
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
  final _searchFocus = FocusNode();

  /// `null` = todos los estados.
  OrderStatus? _statusFilter;
  bool _receivableOnly = false;
  OrderSortColumn _sortColumn = OrderSortColumn.id;
  bool _ascending = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ==================== FILTRADO Y ORDEN ====================

  static bool _isReceivable(OrderSummary o) =>
      o.order.status.countsAsReceivable && o.order.pendingAmount > 0;

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _statusFilter != null ||
      _receivableOnly;

  List<OrderSummary> get _visibleOrders {
    final query = _searchController.text.trim().toLowerCase();
    final list = widget.orders.where((o) {
      if (_statusFilter != null && o.order.status != _statusFilter) {
        return false;
      }
      if (_receivableOnly && !_isReceivable(o)) return false;
      if (query.isEmpty) return true;
      final haystack = [
        o.order.name,
        o.clientName ?? '',
        '#${o.id}',
        '${o.id}',
        o.plateNames ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    Comparable key(OrderSummary o) => switch (_sortColumn) {
      OrderSortColumn.id => o.id,
      OrderSortColumn.date => o.order.date,
      OrderSortColumn.name => o.order.name.toLowerCase(),
      OrderSortColumn.status => o.order.status.index,
      OrderSortColumn.price => o.order.price,
      OrderSortColumn.pending => o.order.pendingAmount,
    };
    list.sort((a, b) {
      final c = Comparable.compare(key(a), key(b));
      // Desempata por número de pedido para un orden estable.
      final result = c != 0 ? c : a.id.compareTo(b.id);
      return _ascending ? result : -result;
    });
    return list;
  }

  void _sortBy(OrderSortColumn column) {
    setState(() {
      if (column == _sortColumn) {
        _ascending = !_ascending;
      } else {
        _sortColumn = column;
        _ascending = switch (column) {
          OrderSortColumn.name || OrderSortColumn.status => true,
          _ => false,
        };
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _statusFilter = null;
      _receivableOnly = false;
    });
  }

  // ==================== ACCIONES ====================

  /// Ejecuta una acción y avisa si falla.
  Future<bool> _attempt(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) AppFeedback.failure(context, e);
      return false;
    }
  }

  void _openForm({Order? edit, Order? duplicate}) {
    showDialog(
      context: context,
      builder: (_) => OrderFormDialog(
        initialOrder: edit,
        duplicateOf: duplicate,
        onSave: widget.onSave,
      ),
    );
  }

  Future<void> _changeStatus(OrderSummary order, OrderStatus status) async {
    final ok = await _attempt(() => widget.onStatusChange(order, status));
    if (ok && mounted) {
      AppFeedback.success(context, AppStrings.statusChanged(status.label));
    }
  }

  Future<void> _complete(OrderSummary order) async {
    final grams = math.max(
      0.0,
      (order.theoreticalGrams ?? 0) - order.wastedGrams,
    );
    final shortages = await _stockShortages(order);
    if (!mounted) return;
    final warning = shortages.isEmpty
        ? ''
        : AppStrings.stockShortageIntro +
              shortages
                  .map(
                    (s) => AppStrings.stockShortageLine(
                      s.materialName,
                      s.neededGrams,
                      s.availableGrams,
                    ),
                  )
                  .join('\n');
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.completeTitle,
      message: AppStrings.completeMessage(grams) + warning,
      confirmText: AppStrings.completeConfirm,
      color: AppColors.success,
      icon: Icons.check_circle_outline,
    );
    if (!confirmed || !mounted) return;
    final ok = await _attempt(() => widget.onComplete(order));
    if (ok && mounted) {
      AppFeedback.success(context, AppStrings.orderCompleted);
    }
  }

  /// Materiales sin stock suficiente para completar [order]; si no se puede
  /// comprobar, no avisa (el repositorio sigue validando al completar).
  Future<List<StockShortage>> _stockShortages(OrderSummary order) async {
    try {
      final plates = await ServiceLocator.orders.getPlates(order.id);
      final waste = await ServiceLocator.orders.getAllWaste();
      final materials = await ServiceLocator.materials.getAll();
      final wasteByMaterial = <int, double>{};
      for (final w in waste) {
        final materialId = w.materialId;
        if (w.orderId != order.id || materialId == null) continue;
        wasteByMaterial[materialId] =
            (wasteByMaterial[materialId] ?? 0) + w.grams;
      }
      return StockCheck.shortages(
        plates: plates,
        wasteByMaterial: wasteByMaterial,
        materials: materials,
      );
    } on Object {
      return const [];
    }
  }

  Future<void> _delete(OrderSummary order) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteOrderTitle,
      message: AppStrings.deleteOrderMessage(order.order.name),
      confirmText: AppStrings.delete,
      color: AppColors.danger,
      icon: Icons.delete_outline,
    );
    if (!confirmed || !mounted) return;
    final ok = await _attempt(() => widget.onDelete(order));
    if (ok && mounted) AppFeedback.success(context, AppStrings.orderDeleted);
  }

  void _registerWaste(OrderSummary order) {
    showDialog(
      context: context,
      builder: (_) => WasteDialog(
        orderId: order.id,
        onSaved: () async {
          await _attempt(widget.onRefresh);
          if (mounted) AppFeedback.warning(context, AppStrings.wasteRegistered);
        },
      ),
    );
  }

  void _onMenu(OrderSummary order, OrderMenuAction action) {
    switch (action) {
      case OrderMenuAction.waste:
        _registerWaste(order);
      case OrderMenuAction.duplicate:
        _openForm(duplicate: order.order);
      case OrderMenuAction.delete:
        _delete(order);
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final visible = _visibleOrders;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _searchFocus.requestFocus(),
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: AppStrings.ordersTitle,
                subtitle: visible.length == widget.orders.length
                    ? AppStrings.ordersCount(widget.orders.length)
                    : AppStrings.showingCount(
                        visible.length,
                        widget.orders.length,
                      ),
                action: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(AppStrings.newOrder),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSearchRow(compact),
              const SizedBox(height: AppSpacing.md),
              _buildFilterChips(),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: Card(child: _buildBody(visible))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<OrderSummary> visible) {
    if (widget.orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: AppStrings.emptyOrdersTitle,
        message: AppStrings.emptyOrdersMessage,
        action: ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 20),
          label: const Text(AppStrings.createFirstOrder),
        ),
      );
    }
    if (visible.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: AppStrings.emptyMatchesTitle,
        message: AppStrings.emptyMatchesMessage,
        action: OutlinedButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.filter_alt_off, size: 18),
          label: const Text(AppStrings.clearFilters),
        ),
      );
    }
    return OrderList(
      orders: visible,
      sortColumn: _sortColumn,
      ascending: _ascending,
      onSort: _sortBy,
      actions: OrderListActions(
        onOpen: (o) => _openForm(edit: o.order),
        onStatusChange: _changeStatus,
        onComplete: _complete,
        onMenu: _onMenu,
      ),
    );
  }

  Widget _buildSearchRow(bool compact) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: AppStrings.searchOrdersHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: AppStrings.clearSearch,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(_searchController.clear),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (compact) ...[
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<OrderSortColumn>(
            tooltip: AppStrings.sortBy,
            icon: const Icon(Icons.sort),
            onSelected: _sortBy,
            itemBuilder: (_) => [
              for (final (column, label) in [
                (OrderSortColumn.id, AppStrings.colIdDate),
                (OrderSortColumn.name, AppStrings.colProject),
                (OrderSortColumn.status, AppStrings.colStatus),
                (OrderSortColumn.price, AppStrings.colFinances),
                (OrderSortColumn.pending, AppStrings.sortPending),
              ])
                CheckedPopupMenuItem(
                  value: column,
                  checked: column == _sortColumn,
                  child: Text(label),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChips() {
    int count(bool Function(OrderSummary) test) =>
        widget.orders.where(test).length;

    Widget chip({
      required String label,
      required int count,
      required bool selected,
      required VoidCallback onTap,
      Color? color,
    }) {
      return FilterChip(
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: color == null
            ? null
            : Icon(Icons.circle, size: 10, color: color),
        label: Text('$label · $count'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            label: AppStrings.filterAll,
            count: widget.orders.length,
            selected: _statusFilter == null && !_receivableOnly,
            onTap: () => setState(() {
              _statusFilter = null;
              _receivableOnly = false;
            }),
          ),
          const SizedBox(width: AppSpacing.sm),
          chip(
            label: AppStrings.filterReceivable,
            count: count(_isReceivable),
            selected: _receivableOnly,
            color: AppColors.warning,
            onTap: () => setState(() {
              _receivableOnly = true;
              _statusFilter = null;
            }),
          ),
          for (final status in OrderStatus.values) ...[
            const SizedBox(width: AppSpacing.sm),
            chip(
              label: status.label,
              count: count((o) => o.order.status == status),
              selected: _statusFilter == status,
              color: statusColor(status),
              onTap: () => setState(() {
                _statusFilter = status;
                _receivableOnly = false;
              }),
            ),
          ],
          if (_hasActiveFilters) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text(AppStrings.clearFilters),
            ),
          ],
        ],
      ),
    );
  }
}
