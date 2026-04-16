import 'package:flutter/material.dart';
import 'package:nesherprints/widgets/order_dialog.dart';
import 'theme/app_colors.dart';
import 'screens/inventory_view.dart';
import 'screens/orders_view.dart';

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
      // Aplicamos tu paleta de colores personalizada a toda la aplicación
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

  // Lista de pantallas importadas de la carpeta 'screens'
  final List<Widget> _screens = [
    const DashboardView(),
    const InventoryView(),
    const OrdersView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- ¡ESTE ES EL BOTÓN FLOTANTE GLOBAL! ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Llama al pop-up que ahora vive en orders_view.dart
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const NewOrderDialog();
            },
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
      // ------------------------------------------
      body: Row(
        children: [
          // Menú lateral (NavigationRail) configurado con tus colores
          NavigationRail(
            backgroundColor: AppColors.secondary,
            indicatorColor: AppColors.primary.withOpacity(0.2),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.textMuted,
            ),
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.textMuted,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Orders'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.black26),
          // Área principal donde se carga la pantalla seleccionada
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

// Mantenemos el Dashboard aquí por ahora para no crear demasiados archivos
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(
                'Total Revenue',
                '1,337.00 €',
                AppColors.statusReservado,
              ),
              _buildStatCard(
                'Total Expenses',
                '591.21 €',
                AppColors.alertBajoStock,
              ),
              _buildStatCard(
                'Net Profit',
                '634.80 €',
                AppColors.statusCompletado,
              ),
              _buildStatCard('Margin', '47.48 %', AppColors.statusEnProceso),
            ],
          ),
          const SizedBox(height: 40),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 80, color: AppColors.secondary),
                  SizedBox(height: 16),
                  Text(
                    "Charts and Analytics will appear here",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color accentColor) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
