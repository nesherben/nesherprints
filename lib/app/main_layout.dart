import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/features/clients/presentation/clients_view.dart';
import 'package:nesherprints/features/dashboard/presentation/dashboard_view.dart';
import 'package:nesherprints/features/extras/presentation/extras_view.dart';
import 'package:nesherprints/features/inventory/presentation/inventory_view.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/presentation/orders_view.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/order_form_dialog.dart';
import 'package:nesherprints/features/settings/presentation/settings_view.dart';

/// Shell de la app: navegación lateral + pantalla activa.
///
/// Es dueño de la lista de pedidos, que comparten el panel y el listado de
/// pedidos. El resto de pantallas cargan sus propios datos al abrirse.
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  List<OrderSummary> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    final data = await ServiceLocator.orders.getAllWithDetails();
    if (!mounted) return;
    setState(() {
      _orders = data;
      _isLoading = false;
    });
  }

  // ==================== ACCIONES SOBRE PEDIDOS ====================

  Future<void> _saveOrder(OrderFormResult result) async {
    final repo = ServiceLocator.orders;
    if (result.order.id == null) {
      await repo.create(
        result.order,
        plates: result.plates,
        extras: result.extras,
      );
    } else {
      // Listas vacías = no tocar placas/piezas existentes.
      await repo.update(
        result.order,
        plates: result.plates.isEmpty ? null : result.plates,
        extras: result.extras.isEmpty ? null : result.extras,
      );
    }
    await _refreshOrders();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.secondary,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _showNewOrderDialog,
                    icon: const Icon(Icons.add),
                    color: AppColors.primary,
                    tooltip: AppStrings.newOrder,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.newOrder,
                    style: TextStyle(fontSize: 12, color: AppColors.textMain),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: Text(AppStrings.navDashboard),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                label: Text(AppStrings.navInventory),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                label: Text(AppStrings.navExtras),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: Text(AppStrings.navOrders),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text(AppStrings.navClients),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text(AppStrings.navSettings),
              ),
            ],
          ),
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }
}
