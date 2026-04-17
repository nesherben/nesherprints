import 'package:flutter/material.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/presentation/screens/dashboard_view.dart';
import 'package:nesherprints/presentation/screens/inventory_view.dart';
import 'package:nesherprints/presentation/screens/orders_view.dart';
import 'package:nesherprints/presentation/widgets/order_dialog.dart';
import 'dart:io'; // Para detectar si estamos en Windows
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // El motor de escritorio
import 'data/repositories/order_repository.dart'; // <--- IMPORTAMOS EL REPOSITORIO
import 'package:nesherprints/presentation/screens/admin_view.dart'; // <--- NUEVO

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos SQLite para Windows/Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const NesherPrintsApp());
}

class NesherPrintsApp extends StatelessWidget {
  const NesherPrintsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NesherPrints ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 4,
          margin: EdgeInsets.all(8),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // 1. Instanciamos el Repositorio
  final OrderRepository _repo = OrderRepository();

  // 2. La lista ahora empieza vacía y añadimos un estado de carga
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshOrders(); // Cargamos los datos al iniciar la app
  }

  // --- LÓGICA DE BASE DE DATOS ---

  // Leer todos los pedidos de SQLite
  Future<void> _refreshOrders() async {
    final data = await _repo.getAllOrders();
    setState(() {
      _allOrders = data;
      _isLoading = false;
    });
  }

  // Crear un nuevo pedido en SQLite
  Future<void> _addNewOrder(Map<String, dynamic> newOrder) async {
    await _repo.insertOrder(newOrder);
    _refreshOrders(); // Recargamos la lista desde la DB
  }

  // Actualizar un pedido en SQLite
  Future<void> _updateOrder(
    Map<String, dynamic> oldOrder,
    Map<String, dynamic> updatedOrder,
  ) async {
    // Es vital pasarle el ID que tenía el pedido original
    updatedOrder['id'] = oldOrder['id'];
    await _repo.updateOrder(updatedOrder);
    _refreshOrders();
  }

  // Borrar de SQLite
  Future<void> _deleteOrder(Map<String, dynamic> order) async {
    await _repo.deleteOrder(order['id']);
    _refreshOrders();
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando la base de datos, mostramos un spinner circular
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final List<Widget> screens = [
      DashboardView(orders: _allOrders),
      const InventoryView(),
      OrdersView(
        orders: _allOrders,
        onDelete: _deleteOrder,
        onUpdate: _updateOrder,
      ),
      const AdminView(),
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => NewOrderDialog(onSave: _addNewOrder),
        ),
        label: const Text('New Order'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
      body: Row(
        children: [
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
                icon: Icon(Icons.settings_outlined),
                label: Text('Admin'),
              ),
            ],
          ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }
}
