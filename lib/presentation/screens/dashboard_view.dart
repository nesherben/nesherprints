import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/material_repository.dart';

class DashboardView extends StatefulWidget {
  final List<Map<String, dynamic>> orders;

  const DashboardView({super.key, required this.orders});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final OrderRepository _orderRepo = OrderRepository();
  final MaterialRepository _materialRepo = MaterialRepository();

  bool _isLoading = true;

  // Métricas calculadas
  double _grossRevenue = 0.0; // Bruto
  double _netRevenue = 0.0; // Neto
  double _pendingRevenue = 0.0;
  Map<String, Map<String, double>> _monthlyData = {}; // Histórico
  Map<String, int> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _calculateFinances();
  }

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orders != oldWidget.orders) {
      _calculateFinances();
    }
  }

  Future<void> _calculateFinances() async {
    setState(() => _isLoading = true);

    final materials = await _materialRepo.getAllMaterials();
    Map<int, double> materialCosts = {};
    for (var m in materials) {
      materialCosts[m['id']] = (m['cost_per_kg'] as num).toDouble();
    }

    double totalGross = 0.0;
    double totalMaterialCost = 0.0;
    double totalWasteCost = 0.0;
    double totalPendingCollect = 0.0; // LO QUE REALMENTE TE DEBEN

    Map<String, Map<String, double>> monthly = {};
    Map<String, int> counts = {
      'Draft': 0,
      'Reserved': 0,
      'In Progress': 0,
      'Completed': 0,
      'Shipped': 0,
      'Canceled': 0,
    };

    for (var o in widget.orders) {
      String status = o['status'];
      double price = (o['price'] as num).toDouble();
      double paid = ((o['paid_amount'] ?? 0) as num).toDouble();
      String month = o['date'].toString().substring(0, 7);

      if (counts.containsKey(status)) counts[status] = counts[status]! + 1;

      // --- NUEVA LÓGICA DE DEUDAS ---
      // Solo nos deben dinero de pedidos que están en marcha o terminados (no borradores ni cancelados)
      if (status != 'Draft' && status != 'Canceled') {
        double owed = price - paid;
        if (owed > 0) {
          totalPendingCollect += owed;
        }
      }

      // --- LÓGICA DE INGRESOS BRUTOS Y NETOS (Solo completados) ---
      if (status == 'Completed' || status == 'Shipped') {
        totalGross += price;

        monthly.putIfAbsent(
          month,
          () => {'gross': 0.0, 'net': 0.0, 'cost': 0.0},
        );
        monthly[month]!['gross'] = monthly[month]!['gross']! + price;

        double orderCost = 0.0;
        final items = await _orderRepo.getOrderItems(o['id']);
        for (var item in items) {
          double kgUsed = (item['grams_used'] as num).toDouble() / 1000;
          double costPerKg = materialCosts[item['material_id']] ?? 0.0;
          orderCost += kgUsed * costPerKg;
        }

        totalMaterialCost += orderCost;
        monthly[month]!['cost'] = monthly[month]!['cost']! + orderCost;
        monthly[month]!['net'] =
            monthly[month]!['gross']! - monthly[month]!['cost']!;
      }
    }

    // Calcular coste de los fallos (order_waste)
    final allWaste = await _orderRepo.getAllWaste();
    for (var w in allWaste) {
      double costPerKg = materialCosts[w['material_id']] ?? 0.0;
      totalWasteCost += (w['grams_wasted'] / 1000) * costPerKg;
    }

    if (mounted) {
      setState(() {
        _grossRevenue = totalGross;
        _netRevenue = totalGross - totalMaterialCost - totalWasteCost;
        _pendingRevenue =
            totalPendingCollect; // Asignamos la deuda real a la tarjeta
        _monthlyData = monthly;
        _statusCounts = counts;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Shipped':
        return AppColors.statusCompletado;
      case 'In Progress':
        return AppColors.primary;
      case 'Reserved':
        return AppColors.statusReservado;
      case 'Canceled':
        return AppColors.statusCancelado;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final totalOrders = widget.orders.length;
    final sortedMonths = _monthlyData.keys.toList()
      ..sort(); // Ordenar cronológicamente

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Financiero',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const Text(
            'Análisis de ingresos brutos, beneficios netos y proyecciones',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 32),

          // 1. TARJETAS DE KPIs (Bruto vs Neto)
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Ingresos Brutos',
                  '€${_grossRevenue.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  AppColors.textMain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'Beneficio Neto (Real)',
                  '€${_netRevenue.toStringAsFixed(2)}',
                  Icons.savings,
                  AppColors.statusCompletado,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'Pendiente de Cobro',
                  '€${_pendingRevenue.toStringAsFixed(2)}',
                  Icons.hourglass_top,
                  AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 2. GRÁFICOS (Histórico Mensual + Pastel de Estados)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GRÁFICO DE BARRAS: HISTÓRICO MENSUAL
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Histórico de Facturación',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.square,
                                    color: AppColors.primary,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text('Bruto', style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.square,
                                    color: AppColors.statusCompletado,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text('Neto', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: sortedMonths.isEmpty
                                ? const Center(
                                    child: Text(
                                      "Completa tu primer pedido para ver el gráfico.",
                                    ),
                                  )
                                : BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: _grossRevenue > 0
                                          ? null
                                          : 100, // Ajuste automático
                                      barTouchData: BarTouchData(enabled: true),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              int index = value.toInt();
                                              if (index >= 0 &&
                                                  index < sortedMonths.length) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Text(
                                                    sortedMonths[index],
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                          ),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: sortedMonths
                                          .asMap()
                                          .entries
                                          .map((e) {
                                            int index = e.key;
                                            String month = e.value;
                                            double gross =
                                                _monthlyData[month]!['gross']!;
                                            double net =
                                                _monthlyData[month]!['net']!;
                                            return BarChartGroupData(
                                              x: index,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: gross,
                                                  color: AppColors.primary,
                                                  width: 16,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                BarChartRodData(
                                                  toY: net,
                                                  color: AppColors
                                                      .statusCompletado,
                                                  width: 16,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ],
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // GRÁFICO CIRCULAR: DISTRIBUCIÓN DE ESTADOS
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text(
                            'Distribución de Pedidos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: totalOrders == 0
                                ? const Center(child: Text("Sin datos"))
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      sections: _statusCounts.entries
                                          .where((e) => e.value > 0)
                                          .map((e) {
                                            final percentage =
                                                (e.value / totalOrders) * 100;
                                            return PieChartSectionData(
                                              color: _getStatusColor(e.key),
                                              value: e.value.toDouble(),
                                              title:
                                                  '${percentage.toStringAsFixed(0)}%',
                                              radius: 50,
                                              titleStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _statusCounts.entries
                                .where((e) => e.value > 0)
                                .map(
                                  (e) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(e.key),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${e.key} (${e.value})',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
