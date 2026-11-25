import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/features/orders/domain/order.dart';

/// Exportación de pedidos a CSV para abrir en Excel (España): separador `;`,
/// coma decimal y BOM UTF-8 para que se vean bien los acentos.
class OrdersCsv {
  OrdersCsv._();

  static const header = [
    'ID',
    'Fecha',
    'Proyecto',
    'Cliente',
    'Estado',
    'Precio',
    'Cobrado',
    'Pendiente',
    'Coste',
    'Beneficio',
    'Para mi',
  ];

  /// Texto CSV de [orders] (una fila por pedido, con cabecera).
  static String build(List<OrderSummary> orders) {
    final buffer = StringBuffer('﻿')..writeln(header.join(';'));
    for (final summary in orders) {
      final o = summary.order;
      final cost = o.costOverride;
      final profit = o.countsAsRevenue && cost != null ? o.price - cost : null;
      buffer.writeln(
        [
          '${summary.id}',
          o.date,
          _text(o.name),
          _text(summary.clientName ?? ''),
          o.status.label,
          _number(o.price),
          _number(o.paidAmount),
          _number(o.pendingAmount),
          cost == null ? '' : _number(cost),
          profit == null ? '' : _number(profit),
          o.isPersonal ? 'Si' : '',
        ].join(';'),
      );
    }
    return buffer.toString();
  }

  static String _number(double v) => formatFieldDecimal(v);

  /// Entrecomilla si hace falta (`;`, comillas o saltos de línea).
  static String _text(String value) {
    final clean = value.replaceAll('\r', ' ');
    if (clean.contains(';') || clean.contains('"') || clean.contains('\n')) {
      return '"${clean.replaceAll('"', '""')}"';
    }
    return clean;
  }
}
