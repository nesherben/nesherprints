import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'presentation/screens/dashboard_view.dart';
import 'presentation/screens/inventory_view.dart';
import 'presentation/screens/orders_view.dart';
import 'presentation/widgets/order_dialog.dart'; // <--- Importante: Importar el diálogo

void main() {
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
          // Corregido: CardThemeData -> CardTheme
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

  // --- ESTADO CENTRALIZADO DE PEDIDOS ---
  final List<Map<String, dynamic>> _allOrders = [
    {
      'name': 'Pennywise 40cm',
      'price': 50.0,
      'date': '2026-02-10',
      'status': 'Completed',
    },
    {
      'name': 'Terminator 40cm',
      'price': 70.0,
      'date': '2026-02-24',
      'status': 'In Progress',
    },
    {
      'name': 'D&D Dragon',
      'price': 120.0,
      'date': '2026-03-01',
      'status': 'Reserved',
    },
  ];

  // 1. FUNCIÓN PARA AÑADIR NUEVOS PEDIDOS
  void _addNewOrder(Map<String, dynamic> newOrder) {
    setState(() {
      _allOrders.add(newOrder);
    });
  }

  void _deleteOrder(Map<String, dynamic> order) {
    setState(() {
      _allOrders.remove(order);
    });
  }

  void _updateOrder(
    Map<String, dynamic> oldOrder,
    Map<String, dynamic> updatedOrder,
  ) {
    setState(() {
      final index = _allOrders.indexOf(oldOrder);
      if (index != -1) {
        _allOrders[index] = updatedOrder;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardView(orders: _allOrders),
      const InventoryView(),
      OrdersView(
        orders: _allOrders,
        onDelete: _deleteOrder,
        onUpdate: _updateOrder, // <--- Nueva función
      ),
    ];
    return Scaffold(
      // 3. AÑADIMOS EL BOTÓN FLOTANTE GLOBAL
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
            ],
          ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }
}
