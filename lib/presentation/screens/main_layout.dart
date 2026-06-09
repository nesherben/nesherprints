import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/service_locator.dart';
import 'dashboard_view.dart';
import 'inventory_view.dart';
import 'extras_view.dart';
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
    final data = await ServiceLocator.orderRepo.getAllOrdersWithDetails();
    setState(() {
      _allOrders = data;
      _isLoading = false;
    });
  }

  // --- FUNCIÓN PARA CREAR NUEVO PEDIDO ---
  Future<void> _addNewOrder(Map<String, dynamic> newOrder) async {
    // 1. Extraemos y borramos la lista del mapa principal
    // Buscamos 'plates' o 'items' por compatibilidad
    final List<dynamic> rawPlates =
        newOrder.remove('plates') ?? newOrder.remove('items') ?? [];

    // 2. Aseguramos el tipo de dato
    final List<Map<String, dynamic>> plates = rawPlates
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // 3. Extraemos extras y limpiamos el mapa
    final List<dynamic> rawExtras = newOrder.remove('extras') ?? [];
    final List<Map<String, dynamic>> extras = rawExtras
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // 4. Guardar pedido con placas y extras
    await ServiceLocator.orderRepo.insertOrder(
      newOrder,
      plates,
      extras: extras,
    );

    // 4. Refrescar la pantalla
    _refreshOrders(); // O la función que uses para recargar tu estado
  }

  // --- FUNCIÓN PARA ACTUALIZAR PEDIDO ---
  Future<void> _updateOrder(
    Map<String, dynamic> oldOrder,
    Map<String, dynamic> updatedOrder,
  ) async {
    // 1. Extraemos y borramos la lista igual que arriba
    final List<dynamic> rawPlates =
        updatedOrder.remove('plates') ?? updatedOrder.remove('items') ?? [];

    // 2. Aseguramos el tipo
    final List<Map<String, dynamic>> plates = rawPlates
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final List<dynamic> rawExtras = updatedOrder.remove('extras') ?? [];
    final List<Map<String, dynamic>> extras = rawExtras
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // 3. Guardamos los cambios limpios
    if (plates.isNotEmpty) {
      await ServiceLocator.orderRepo.updateOrder(updatedOrder, plates);
    } else {
      await ServiceLocator.orderRepo.updateOrder(
        updatedOrder,
      ); // Por si solo se cambia el estado desde la tabla
    }
    // Si hay extras en la actualización, pasarlos en el mismo mapa para que se guarden
    if (extras.isNotEmpty) {
      updatedOrder['extras'] = extras;
      await ServiceLocator.orderRepo.updateOrder(updatedOrder);
    }

    _refreshOrders();
  }

  /// Elimina un pedido de SQLite
  Future<void> _deleteOrder(Map<String, dynamic> order) async {
    await ServiceLocator.orderRepo.deleteOrder(order['id']);
    _refreshOrders();
  }

  /// Marca un pedido como completado y reduce el stock de materiales
  Future<void> _completeOrder(Map<String, dynamic> order) async {
    final updatedOrder = Map<String, dynamic>.from(order);

    // 1. Cambiamos el estado a Completado
    updatedOrder['status'] = OrderStatus.completed;

    // 2. ---> ¡LA CLAVE QUE FALTABA! <---
    // Le decimos a la base de datos que el dinero pagado ahora es igual al precio total
    updatedOrder['paid_amount'] = updatedOrder['price'];

    // 3. Guardamos en DB
    await ServiceLocator.orderRepo.updateOrder(updatedOrder);

    // 4. Restamos stock por placas
    final plates = await ServiceLocator.orderRepo.getOrderPlates(order['id']);
    for (var plate in plates) {
      await ServiceLocator.materialRepo.reduceStock(
        plate['material_id'],
        (plate['grams'] as num).toDouble(),
      );
    }

    // 5. Refrescamos
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
      const ExtrasView(),
      OrdersView(
        orders: _allOrders,
        onDelete: _deleteOrder,
        onUpdate: _updateOrder,
        onComplete: _completeOrder,
        onRefresh: _refreshOrders,
      ),
      const ClientsView(),
      const AdminView(),
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewOrderDialog,
        label: Text(UiStrings.newOrder),
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
                label: Text(UiStrings.dashboard),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                label: Text(UiStrings.inventory),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                label: Text(UiStrings.pieces),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: Text(UiStrings.orders),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text(UiStrings.clients),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text(UiStrings.admin),
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
