/// Número para un campo de texto, con coma decimal y sin separador de miles
/// (`7.5` → `7,50`). Los campos aceptan coma o punto al teclear.
String formatFieldDecimal(double value, {int decimals = 2}) =>
    value.toStringAsFixed(decimals).replaceAll('.', ',');

/// Número con formato español: miles con punto y decimales con coma
/// (`5485.5` → `5.485,50`).
String formatNumberEs(double value, {int decimals = 2}) {
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final negative = value < 0 && double.parse(fixed) != 0;
  return '${negative ? '-' : ''}$intPart'
      '${parts.length > 1 ? ',${parts[1]}' : ''}';
}

/// Importe en euros con 2 decimales: `12,50 €`, `5.485,00 €`.
String formatEuro(double value, {int decimals = 2}) =>
    '${formatNumberEs(value, decimals: decimals)} €';

/// Fecha de hoy en formato `YYYY-MM-DD` (formato guardado en `orders.date`).
String todayIsoDate([DateTime? now]) =>
    (now ?? DateTime.now()).toString().split(' ')[0];

/// Número para mostrarlo en un campo de texto sin ceros sobrantes:
/// `100.0` → `100`, `2.5` → `2.5`.
String formatInputNumber(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

/// Duración legible a partir de minutos: `45 min`, `2 h`, `3 h 20 min`.
String formatDuration(double minutes) {
  final total = minutes.round();
  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}

/// Importe compacto para ejes de gráficas: `950 €`, `1,2k €`.
String formatEuroCompact(double value) {
  final abs = value.abs();
  if (abs >= 1000) {
    final k = value / 1000;
    return '${formatNumberEs(k, decimals: k.abs() >= 10 ? 0 : 1)}k €';
  }
  return '${formatNumberEs(value, decimals: 0)} €';
}

const _monthNames = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// `2026-11` → `nov 2026`. Cualquier otro texto se devuelve tal cual.
String formatMonth(String yearMonth) {
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(yearMonth);
  if (match == null) return yearMonth;
  final month = int.parse(match.group(2)!);
  if (month < 1 || month > 12) return yearMonth;
  return '${_monthNames[month - 1]} ${match.group(1)}';
}

/// Porcentaje con un decimal: `0.675` → `67,5 %`.
String formatPercent(double ratio, {int decimals = 0}) =>
    '${formatNumberEs(ratio * 100, decimals: decimals)} %';
