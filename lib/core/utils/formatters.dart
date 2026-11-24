/// Importe en euros con 2 decimales: `€12.50`.
String formatEuro(double value, {int decimals = 2}) =>
    '€${value.toStringAsFixed(decimals)}';

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

/// Importe compacto para ejes de gráficas: `€950`, `€1.2k`.
String formatEuroCompact(double value) {
  final abs = value.abs();
  if (abs >= 1000) {
    final k = value / 1000;
    return '€${k.toStringAsFixed(k.abs() >= 10 ? 0 : 1)}k';
  }
  return '€${value.toStringAsFixed(0)}';
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

/// Porcentaje con un decimal: `0.675` → `67.5 %`.
String formatPercent(double ratio, {int decimals = 0}) =>
    '${(ratio * 100).toStringAsFixed(decimals)} %';
