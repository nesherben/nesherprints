// Utilities for parsing numbers with flexible decimal separators

double parseDecimal(String? input, {double fallback = 0.0}) {
  if (input == null) return fallback;
  final normalized = input.replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? fallback;
}
