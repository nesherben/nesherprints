import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';

/// Resumen mensual en CSV para la gestoría o para Excel: separador `;`, coma
/// decimal y BOM UTF-8. Una fila por mes (cronológica) y una de totales.
class MonthlyCsv {
  MonthlyCsv._();

  static const header = [
    'Mes',
    'Pedidos',
    'Facturado',
    'Coste',
    'Beneficio',
    'Margen %',
  ];

  static String build(FinanceSummary summary) {
    final buffer = StringBuffer('﻿')..writeln(header.join(';'));
    for (final e in summary.monthly.entries) {
      buffer.writeln(_row(e.key, e.value));
    }
    buffer.writeln(
      _row(
        'Total',
        MonthStats(
          orders: summary.completedOrders,
          gross: summary.grossRevenue,
          cost: summary.cost,
        ),
      ),
    );
    return buffer.toString();
  }

  static String _row(String month, MonthStats m) => [
    month,
    '${m.orders}',
    formatFieldDecimal(m.gross),
    formatFieldDecimal(m.cost),
    formatFieldDecimal(m.profit),
    formatFieldDecimal(m.ratio * 100, decimals: 1),
  ].join(';');
}
