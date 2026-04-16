import 'package:flutter/material.dart';
import 'theme/app_colors.dart'; // ¡Aquí llamamos a tus colores!

void main() {
  runApp(const Gestion3DApp());
}

class Gestion3DApp extends StatelessWidget {
  const Gestion3DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP Impresión 3D',
      debugShowCheckedModeBanner: false,
      // AQUÍ INYECTAMOS TU PALETA DE COLORES A TODA LA APP
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
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _indiceSeleccionado = 0;

  // Las pantallas de tu app
  final List<Widget> _pantallas = [
    const DashboardView(),
    const InventarioView(),
    const PedidosView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // MENÚ LATERAL (Navigation Rail)
          NavigationRail(
            backgroundColor: AppColors.secondary, // Color oscuro para el menú
            indicatorColor: AppColors.primary.withOpacity(0.2), // Resaltado sutil
            selectedIndex: _indiceSeleccionado,
            onDestinationSelected: (int index) {
              setState(() {
                _indiceSeleccionado = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventario'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Pedidos'),
              ),
            ],
          ),
          // CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: AppColors.background,
              child: _pantallas[_indiceSeleccionado],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// PANTALLAS (Vistas)
// =========================================================

// --- PANTALLA 1: DASHBOARD ---
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
            'Resumen Financiero', 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _crearTarjeta('Ingresos', '1.337,00 €', AppColors.statusReservado),
              _crearTarjeta('Gastos', '591,21 €', AppColors.alertBajoStock),
              _crearTarjeta('Beneficio Neto', '634,80 €', AppColors.statusCompletado),
              _crearTarjeta('Margen', '47.48 %', AppColors.statusEnProceso),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: Text(
                "Espacio reservado para el Gráfico Mensual 📊",
                style: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget reutilizable para las tarjetas del dashboard
  Widget _crearTarjeta(String titulo, String valor, Color colorAcento) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo, 
                style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                valor, 
                style: TextStyle(color: colorAcento, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA 2: INVENTARIO (Estructura base) ---
class InventarioView extends StatelessWidget {
  const InventarioView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('🛢️ Sección de Tanque de Resina y Filamentos', style: TextStyle(color: AppColors.textMain, fontSize: 24)),
    );
  }
}

// --- PANTALLA 3: PEDIDOS (Estructura base) ---
class PedidosView extends StatelessWidget {
  const PedidosView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('📋 Tabla histórica y formulario de nuevos encargos', style: TextStyle(color: AppColors.textMain, fontSize: 24)),
    );
  }
}
