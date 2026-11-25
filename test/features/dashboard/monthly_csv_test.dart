import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';
import 'package:nesherprints/features/dashboard/domain/monthly_csv.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

void main() {
  test('resumen mensual: filas por mes y total con coma decimal', () {
    final summary = FinanceSummary(
      completedOrders: 3,
      grossRevenue: 300,
      cost: 100,
      pendingCollection: 0,
      profitGoal: 5000,
      monthly: const {
        '2026-01': MonthStats(orders: 1, gross: 100, cost: 25),
        '2026-02': MonthStats(orders: 2, gross: 200, cost: 75),
      },
      statusCounts: {for (final s in OrderStatus.values) s: 0},
      pendingOrders: const [],
      wasteCost: 0,
      wasteGrams: 0,
      wasteRecords: 0,
    );
    final lines = MonthlyCsv.build(
      summary,
    ).replaceFirst('\uFEFF', '').trim().split('\n');
    expect(lines.first, 'Mes;Pedidos;Facturado;Coste;Beneficio;Margen %');
    expect(lines[1], '2026-01;1;100,00;25,00;75,00;75,0');
    expect(lines[2], '2026-02;2;200,00;75,00;125,00;62,5');
    expect(lines.last, 'Total;3;300,00;100,00;200,00;66,7');
  });
}
