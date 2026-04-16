import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';

class DashboardView extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const DashboardView({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA DE DATOS PARA EL GRÁFICO ---
    // Agrupamos ingresos por mes (1-12)
    Map<int, double> monthlyRevenue = {for (var i = 1; i <= 12; i++) i: 0.0};

    double totalRevenue = 0;
    int completedCount = 0;

    for (var o in orders) {
      if (o['status'] == 'Completed' || o['status'] == 'Shipped') {
        double price = (o['price'] as num).toDouble();
        totalRevenue += price;
        completedCount++;

        // Extraer mes de la fecha "2026-03-28"
        try {
          int month = int.parse(o['date'].split('-')[1]);
          monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + price;
        } catch (_) {}
      }
    }

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

          // TARJETAS SUPERIORES
          Row(
            children: [
              _buildStatCard(
                'Revenue',
                '€${totalRevenue.toStringAsFixed(2)}',
                AppColors.statusReservado,
              ),
              _buildStatCard(
                'Profit (Est.)',
                '€${(totalRevenue * 0.6).toStringAsFixed(2)}',
                AppColors.statusCompletado,
              ),
              _buildStatCard('Jobs Done', '$completedCount', AppColors.primary),
              _buildStatCard(
                'Active',
                '${orders.length - completedCount}',
                AppColors.statusEnProceso,
              ),
            ],
          ),

          const SizedBox(height: 40),
          const Text(
            'Monthly Revenue Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // --- EL GRÁFICO ---
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (totalRevenue > 0)
                        ? totalRevenue * 1.2
                        : 100, // Ajuste dinámico de altura
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.secondary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '€${rod.toY.toStringAsFixed(2)}',
                            const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            return Text(
                              months[value.toInt() - 1],
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: monthlyRevenue.entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value,
                            color: AppColors.primary,
                            width: 25,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: (totalRevenue > 0)
                                  ? totalRevenue * 1.2
                                  : 100,
                              color: AppColors.background,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
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
