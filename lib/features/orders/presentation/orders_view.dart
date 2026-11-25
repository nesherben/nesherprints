import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/errors/app_exception.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/domain/stock_check.dart';
import 'package:nesherprints/features/orders/presentation/status_style.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/order_form_dialog.dart';
import 'package:nesherprints/features/orders/presentation/widgets/assign_client_dialog.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_list.dart';
import 'package:nesherprints/features/orders/presentation/widgets/quick_order_bar.dart';
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
  final _quickFocus = FocusNode();
  final _rootFocus = FocusNode();
  List<Client> _clients = const [];

  /// Pedido marcado con el teclado (↑ ↓ Intro).
  int? _selectedId;

  /// `null` = todos los estados.
  OrderStatus? _statusFilter;
  bool _receivableOnly = false;
  bool _personalOnly = false;
  OrderSortColumn _sortColumn = OrderSortColumn.id;
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
    // Al entrar, el foco es de la pantalla para que las flechas funcionen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(OrdersView old) {
    super.didUpdateWidget(old);
    // Un cliente nuevo (creado desde el formulario) aparece al recargar.
    if (old.orders != widget.orders) _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await ServiceLocator.clients.getAll();
      if (!mounted) return;
      setState(() => _clients = clients);
    } on Object {
      // Sin clientes solo se pierde la lista del desplegable.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _quickFocus.dispose();
    _rootFocus.dispose();
    super.dispose();
  }

  // ==================== FILTRADO Y ORDEN ====================

  static bool _isReceivable(OrderSummary o) =>
      o.order.status.countsAsReceivable && o.order.pendingAmount > 0;

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _statusFilter != null ||
      _receivableOnly ||
      _personalOnly;

  List<OrderSummary> get _visibleOrders {
    final query = _searchController.text.trim().toLowerCase();
    final list = widget.orders.where((o) {
      if (_statusFilter != null && o.order.status != _statusFilter) {
        return false;
      }
      if (_receivableOnly && !_isReceivable(o)) return false;
      if (_personalOnly && !o.order.isPersonal) return false;
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
      _personalOnly = false;
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
      case OrderMenuAction.personal:
        _markPersonal(order);
      case OrderMenuAction.collect:
        _markPaid(order);
      case OrderMenuAction.delete:
        _delete(order);
    }
  }

  /// Alta rápida de un borrador (sin placas) desde la barra de la tabla.
  Future<void> _quickCreate(String name, int? clientId, double price) async {
    final ok = await _attempt(() async {
      await ServiceLocator.orders.create(
        Order(
          clientId: clientId,
          name: name,
          price: price,
          date: todayIsoDate(),
          status: OrderStatus.draft,
        ),
        plates: const [],
      );
      await widget.onRefresh();
    });
    if (!ok) throw const AppException('No se pudo crear el pedido.');
    if (mounted) AppFeedback.success(context, AppStrings.quickOrderCreated);
  }

  /// Edición rápida de la tabla: si falla avisa y relanza para que la celda
  /// no dé el cambio por hecho.
  Future<void> _quickEdit(Future<void> Function() action) async {
    await _attempt(() async {
      await action();
      await widget.onRefresh();
    });
  }

  /// Mueve la selección del teclado [delta] filas por la lista visible.
  void _moveSelection(int delta) {
    final list = _visibleOrders;
    if (list.isEmpty) return;
    final current = list.indexWhere((o) => o.id == _selectedId);
    final next = current < 0
        ? (delta > 0 ? 0 : list.length - 1)
        : (current + delta).clamp(0, list.length - 1);
    setState(() => _selectedId = list[next].id);
  }

  void _openSelected() {
    final match = widget.orders.where((o) => o.id == _selectedId);
    if (match.isNotEmpty) _openForm(edit: match.first.order);
  }

  /// Los atajos de flechas no deben robar las teclas a un campo de texto.
  bool get _typing =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  Future<void> _assignClient(List<OrderSummary> orders) async {
    final result = await showDialog<AssignClientResult>(
      context: context,
      builder: (_) =>
          AssignClientDialog(count: orders.length, clients: _clients),
    );
    if (result == null || !mounted) return;
    final ok = await _attempt(() async {
      await ServiceLocator.orders.setClientMany([
        for (final o in orders) o.id,
      ], result.clientId);
      await widget.onRefresh();
    });
    if (ok && mounted) {
      AppFeedback.success(context, AppStrings.clientAssigned(orders.length));
    }
  }

  Future<void> _markPaid(OrderSummary order) async {
    final ok = await _attempt(() async {
      await ServiceLocator.orders.markPaid(order.id);
      await widget.onRefresh();
    });
    if (ok && mounted) AppFeedback.success(context, AppStrings.collectedDone);
  }

  Future<void> _markPersonal(OrderSummary order) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.markPersonalTitle,
      message: AppStrings.markPersonalMessage(order.order.name),
      confirmText: AppStrings.markPersonalConfirm,
      color: AppColors.info,
      icon: Icons.person_outline,
    );
    if (!confirmed || !mounted) return;
    final ok = await _attempt(() async {
      await ServiceLocator.orders.markPersonal(order.id);
      await widget.onRefresh();
    });
    if (ok && mounted) {
      AppFeedback.success(context, AppStrings.markedPersonal);
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
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          if (!_typing) _moveSelection(1);
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          if (!_typing) _moveSelection(-1);
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_typing) _openSelected();
        },
        // Ctrl+Mayús+N: al alta rápida.
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
          shift: true,
        ): () =>
            _quickFocus.requestFocus(),
      },
      child: Focus(
        focusNode: _rootFocus,
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
                // En móvil ya está el botón «+» flotante.
                action: compact
                    ? null
                    : ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text(AppStrings.newOrder),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!compact) ...[
                QuickOrderBar(
                  clients: _clients,
                  focusNode: _quickFocus,
                  onCreate: _quickCreate,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _buildSearchRow(compact),
              const SizedBox(height: AppSpacing.md),
              _buildFilterChips(compact),
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
      selectedId: _selectedId,
      actions: OrderListActions(
        onOpen: (o) => _openForm(edit: o.order),
        onStatusChange: _changeStatus,
        onComplete: _complete,
        onMenu: _onMenu,
        clients: _clients,
        onSetPrice: (o, v) =>
            _quickEdit(() => ServiceLocator.orders.setMoney(o.id, price: v)),
        onSetPaid: (o, v) =>
            _quickEdit(() => ServiceLocator.orders.setMoney(o.id, paid: v)),
        onSetClient: (o, id) =>
            _quickEdit(() => ServiceLocator.orders.setClient(o.id, id)),
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

  Widget _buildFilterChips(bool compact) {
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

    final visibleNow = _hasActiveFilters
        ? _visibleOrders
        : const <OrderSummary>[];
    final children = <Widget>[
      chip(
        label: AppStrings.filterAll,
        count: widget.orders.length,
        selected: _statusFilter == null && !_receivableOnly && !_personalOnly,
        onTap: () => setState(() {
          _statusFilter = null;
          _receivableOnly = false;
          _personalOnly = false;
        }),
      ),
      chip(
        label: AppStrings.filterReceivable,
        count: count(_isReceivable),
        selected: _receivableOnly,
        color: AppColors.warning,
        onTap: () => setState(() {
          _receivableOnly = true;
          _personalOnly = false;
          _statusFilter = null;
        }),
      ),
      // Los estados sin pedidos no ocupan sitio (salvo el elegido).
      for (final status in OrderStatus.values)
        if (_statusFilter == status ||
            count((o) => o.order.status == status) > 0) ...[
          chip(
            label: status.label,
            count: count((o) => o.order.status == status),
            selected: _statusFilter == status,
            color: statusColor(status),
            onTap: () => setState(() {
              _statusFilter = status;
              _receivableOnly = false;
              _personalOnly = false;
            }),
          ),
        ],
      // Solo si hay pedidos para mí.
      if (_personalOnly || count((o) => o.order.isPersonal) > 0)
        chip(
          label: AppStrings.personalOrder,
          count: count((o) => o.order.isPersonal),
          selected: _personalOnly,
          color: AppColors.info,
          onTap: () => setState(() {
            _personalOnly = true;
            _receivableOnly = false;
            _statusFilter = null;
          }),
        ),
      if (_hasActiveFilters) ...[
        TextButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.filter_alt_off, size: 18),
          label: const Text(AppStrings.clearFilters),
        ),
        // Con un filtro activo, asignar cliente a todos los que se ven.
        if (visibleNow.isNotEmpty && visibleNow.length < widget.orders.length)
          TextButton.icon(
            onPressed: () => _assignClient(visibleNow),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: Text(
              '${AppStrings.assignClientAction} (${visibleNow.length})',
            ),
          ),
      ],
    ];
    // En móvil una sola línea que se desliza; en ancho, varias si hace falta.
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              c,
            ],
          ],
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
