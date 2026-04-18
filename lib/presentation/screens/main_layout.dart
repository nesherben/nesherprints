import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/material_repository.dart';
import 'dashboard_view.dart';
import 'inventory_view.dart';
import 'orders_view.dart';
import 'clients_view.dart';
import 'admin_view.dart';
import '../widgets/forms/order_form_dialog.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // --- REPOSITORIOS ---
  final OrderRepository _orderRepo = OrderRepository();
  final MaterialRepository _materialRepo = MaterialRepository();

  // --- ESTADO ---
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  // --- MÉTODOS DE BASE DE DATOS ---

  /// Carga todos los pedidos desde SQLite
  Future<void> _refreshOrders() async {
    final data = await _orderRepo.getAllOrders();
    setState(() {
      _allOrders = data;
      _isLoading = false;
    });
  }

  /// Crea un nuevo pedido en SQLite
  Future<void> _addNewOrder(Map<String, dynamic> newOrder) async {
    List<Map<String, dynamic>> items = newOrder.remove('items');
    await _orderRepo.insertOrder(newOrder, items: items);
    _refreshOrders();
  }

  /// Actualiza un pedido existente en SQLite
  Future<void> _updateOrder(
    Map<String, dynamic> oldOrder,
    Map<String, dynamic> updatedOrder,
  ) async {
    updatedOrder['id'] = oldOrder['id'];
    List<Map<String, dynamic>> items = updatedOrder.remove('items');
    await _orderRepo.updateOrder(updatedOrder, items: items);
    _refreshOrders();
  }

  /// Elimina un pedido de SQLite
  Future<void> _deleteOrder(Map<String, dynamic> order) async {
    await _orderRepo.deleteOrder(order['id']);
    _refreshOrders();
  }

  /// Marca un pedido como completado y reduce el stock de materiales
  Future<void> _completeOrder(Map<String, dynamic> order) async {
    // 1. Clonamos el pedido y cambiamos el estado
    final updatedOrder = Map<String, dynamic>.from(order);
    updatedOrder['status'] = 'Completed';

    // 2. Guardamos el nuevo estado en la base de datos
    await _orderRepo.updateOrder(updatedOrder);

    // 3. Buscamos los materiales usados y restamos el stock
    final items = await _orderRepo.getOrderItems(order['id']);
    for (var item in items) {
      await _materialRepo.reduceStock(item['material_id'], item['grams_used']);
    }

    // 4. Refrescamos la pantalla
    _refreshOrders();
  }

  /// Abre el diálogo para crear un nuevo pedido
  void _showNewOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => OrderFormDialog(onSave: _addNewOrder),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar spinner mientras carga
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Lista de pantallas que se mostrarán según el índice seleccionado
    final List<Widget> screens = [
      DashboardView(orders: _allOrders),
      const InventoryView(),
      OrdersView(
        orders: _allOrders,
        onDelete: _deleteOrder,
        onUpdate: _updateOrder,
        onComplete: _completeOrder,
      ),
      const ClientsView(),
      const AdminView(),
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewOrderDialog,
        label: const Text('New Order'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
      body: Row(
        children: [
          // --- NAVEGACIÓN LATERAL ---
          NavigationRail(
            backgroundColor: AppColors.secondary,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: Text('Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Clientes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('Admin'),
              ),
            ],
          ),

          // --- CONTENIDO PRINCIPAL ---
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }
}
