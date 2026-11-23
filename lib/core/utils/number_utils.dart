/// Convierte texto a `double` aceptando coma o punto decimal.
double parseDecimal(String? input, {double fallback = 0.0}) {
  if (input == null) return fallback;
  final normalized = input.replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? fallback;
}

/// Convierte texto a `int`; devuelve [fallback] si no es válido.
int parseInt(String? input, {int fallback = 0}) {
  if (input == null) return fallback;
  return int.tryParse(input.trim()) ?? fallback;
}

/// Lee un número de un mapa de SQLite como `double`.
double asDouble(Object? value, {double fallback = 0.0}) =>
    value is num ? value.toDouble() : fallback;
