import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/features/clients/presentation/clients_view.dart';
import 'package:nesherprints/features/dashboard/presentation/dashboard_view.dart';
import 'package:nesherprints/features/extras/presentation/extras_view.dart';
import 'package:nesherprints/features/inventory/presentation/inventory_view.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/presentation/orders_view.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/order_form_dialog.dart';
import 'package:nesherprints/features/settings/presentation/settings_view.dart';

class _Destination {
  const _Destination(
    this.label,
    this.icon,
    this.selectedIcon, {
    this.shortLabel,
  });

  final String label;

  /// Etiqueta más corta para la barra inferior (si la normal no cabe).
  final String? shortLabel;
  final IconData icon;
  final IconData selectedIcon;
}

/// Shell de la app: navegación + pantalla activa.
///
/// - Ventana ancha: barra lateral extendida; media: barra lateral compacta;
///   estrecha: barra inferior.
/// - Atajos: `Ctrl+N` nuevo pedido, `Ctrl+1…6` cambia de sección.
///
/// Es dueño de la lista de pedidos, que comparten el panel y el listado de
/// pedidos. El resto de pantallas cargan sus propios datos al abrirse.
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const _destinations = [
    _Destination(
      AppStrings.navDashboard,
      Icons.dashboard_outlined,
      Icons.dashboard,
    ),
    _Destination(
      AppStrings.navInventory,
      Icons.inventory_2_outlined,
      Icons.inventory_2,
    ),
    _Destination(AppStrings.navExtras, Icons.category_outlined, Icons.category),
    _Destination(
      AppStrings.navOrders,
      Icons.receipt_long_outlined,
      Icons.receipt_long,
    ),
    _Destination(AppStrings.navClients, Icons.people_outline, Icons.people),
    _Destination(
      AppStrings.navSettings,
      Icons.settings_outlined,
      Icons.settings,
      shortLabel: AppStrings.navSettingsShort,
    ),
  ];

  /// `Ctrl+1…6` selecciona la sección de ese número.
  static final _digitKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
  ];

  /// Ancho de la barra lateral extendida.
  static const double _railWidth = 212;

  static const _dashboardIndex = 0;
  static const _ordersIndex = 3;

  int _selectedIndex = 0;
  List<OrderSummary> _orders = [];
  bool _isLoading = true;
  Object? _loadError;

  /// Se incrementa para obligar a la pantalla activa a recargar sus datos
  /// cuando un pedido guardado puede haberlos cambiado (stock de piezas…).
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    try {
      final data = await ServiceLocator.orders.getAllWithDetails();
      if (!mounted) return;
      setState(() {
        _orders = data;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e;
      });
    }
  }

  // ==================== ACCIONES SOBRE PEDIDOS ====================
  // Lanzan si fallan: quien las llama (formulario o listado) avisa al usuario.

  Future<void> _saveOrder(OrderFormResult result) async {
    final repo = ServiceLocator.orders;
    if (result.order.id == null) {
      await repo.create(
        result.order,
        plates: result.plates,
        extras: result.extras,
      );
    } else {
      await repo.update(
        result.order,
        plates: result.plates,
        extras: result.extras,
      );
    }
    await _refreshOrders();
    if (!mounted) return;
    // Un pedido gasta piezas: las pantallas de datos que no son pedidos ni
    // panel se recargan para no mostrar stock viejo.
    if (_selectedIndex != _dashboardIndex && _selectedIndex != _ordersIndex) {
      setState(() => _revision++);
    }
    AppFeedback.success(context, AppStrings.orderSaved);
  }

  Future<void> _changeStatus(OrderSummary order, OrderStatus status) async {
    await ServiceLocator.orders.updateStatus(order.id, status);
    await _refreshOrders();
  }

  Future<void> _completeOrder(OrderSummary order) async {
    await ServiceLocator.orders.complete(order.id);
    await _refreshOrders();
  }

  Future<void> _deleteOrder(OrderSummary order) async {
    await ServiceLocator.orders.delete(order.id);
    await _refreshOrders();
  }

  void _showNewOrderDialog() {
    showDialog(
      context: context,
      builder: (_) => OrderFormDialog(onSave: _saveOrder),
    );
  }

  void _select(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  // ==================== UI ====================

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardView(orders: _orders);
      case 1:
        return const InventoryView();
      case 2:
        return const ExtrasView();
      case 3:
        return OrdersView(
          orders: _orders,
          onSave: _saveOrder,
          onStatusChange: _changeStatus,
          onComplete: _completeOrder,
          onDelete: _deleteOrder,
          onRefresh: _refreshOrders,
        );
      case 4:
        return const ClientsView();
      default:
        return const SettingsView();
    }
  }

  Widget _buildContent() {
    if (_loadError != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: AppStrings.loadErrorTitle,
        message: AppFeedback.describe(_loadError!),
        action: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isLoading = true;
              _loadError = null;
            });
            _refreshOrders();
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text(AppStrings.retry),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: KeyedSubtree(
        key: ValueKey('$_selectedIndex-$_revision'),
        child: _buildScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final compact = context.isCompact;
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          _showNewOrderDialog,
      for (final (i, key) in _digitKeys.indexed)
        SingleActivator(key, control: true): () => _select(i),
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: compact
              ? SafeArea(child: _buildContent())
              : Row(
                  children: [
                    _buildRail(extended: context.isWide),
                    const VerticalDivider(),
                    Expanded(child: _buildContent()),
                  ],
                ),
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.shortLabel ?? d.label,
                      ),
                  ],
                )
              : null,
          floatingActionButton:
              compact &&
                  (_selectedIndex == _dashboardIndex ||
                      _selectedIndex == _ordersIndex)
              ? FloatingActionButton(
                  onPressed: _showNewOrderDialog,
                  tooltip: AppStrings.newOrder,
                  child: const Icon(Icons.add),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildRail({required bool extended}) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              extended: extended,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              minExtendedWidth: _railWidth,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                // La barra extendida no impone ancho a su cabecera: se lo damos
                // (ancho mínimo de la barra menos el relleno).
                child: SizedBox(
                  width: extended ? _railWidth - 2 * AppSpacing.md : null,
                  child: Column(
                    children: [
                      _Brand(extended: extended),
                      const SizedBox(height: AppSpacing.xl),
                      if (extended)
                        FloatingActionButton.extended(
                          onPressed: _showNewOrderDialog,
                          tooltip: AppStrings.newOrder,
                          elevation: 0,
                          icon: const Icon(Icons.add),
                          label: const Text(AppStrings.newOrder),
                        )
                      else
                        FloatingActionButton(
                          onPressed: _showNewOrderDialog,
                          tooltip: AppStrings.newOrder,
                          elevation: 0,
                          child: const Icon(Icons.add),
                        ),
                    ],
                  ),
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logotipo y nombre de la app en la cabecera de la barra lateral.
class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(Icons.view_in_ar, color: AppColors.primary, size: 22),
    );
    if (!extended) return mark;
    return Row(
      children: [
        mark,
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Text(
            AppStrings.brandName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
