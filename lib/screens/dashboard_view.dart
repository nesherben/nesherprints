import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DashboardView extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const DashboardView({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA DE CÁLCULO REAL ---
    double totalRevenue = 0;
    int completedOrders = 0;

    for (var order in orders) {
      if (order['status'] == 'Completed' || order['status'] == 'Shipped') {
        totalRevenue += order['price'];
        completedOrders++;
      }
    }

    // Supongamos un gasto fijo del 40% para el ejemplo del beneficio
    double estimatedExpenses = totalRevenue * 0.40;
    double netProfit = totalRevenue - estimatedExpenses;

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
                '€${totalRevenue.toStringAsFixed(2)}',
                AppColors.statusReservado,
              ),
              _buildStatCard(
                'Net Profit (Est.)',
                '€${netProfit.toStringAsFixed(2)}',
                AppColors.statusCompletado,
              ),
              _buildStatCard(
                'Completed Jobs',
                '$completedOrders',
                AppColors.primary,
              ),
              _buildStatCard(
                'Active Projects',
                '${orders.length - completedOrders}',
                AppColors.statusEnProceso,
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_graph, size: 80, color: AppColors.secondary),
                  SizedBox(height: 16),
                  Text(
                    "Analytics will sync with your orders history",
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
