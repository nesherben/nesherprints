/// Un color de filamento leído de una lista pegada.
class BulkColor {
  const BulkColor(this.color, this.pricePerKg);

  final String color;

  /// Precio propio de la línea, o `null` si usa el de por defecto.
  final double? pricePerKg;
}

/// Lee una lista de colores para dar de alta muchos filamentos de golpe
/// (lógica pura).
///
/// Cada línea (o cada trozo separado por `;`) es un color, con precio propio
/// opcional: `Rojo`, `Rojo: 18`, `Azul = 17,5`. Se ignoran las líneas vacías y
/// los colores repetidos (sin distinguir mayúsculas).
class BulkFilaments {
  BulkFilaments._();

  static final _withPrice = RegExp(r'^(.*?)\s*[:=]\s*(\d+(?:[.,]\d+)?)\s*€?$');

  static List<BulkColor> parse(String text) {
    final seen = <String>{};
    final result = <BulkColor>[];
    for (final raw in text.split(RegExp(r'[\n;]'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      var color = line;
      double? price;
      final m = _withPrice.firstMatch(line);
      if (m != null) {
        color = m.group(1)!.trim();
        price = double.tryParse(m.group(2)!.replaceAll(',', '.'));
      }
      if (color.isEmpty || !seen.add(color.toLowerCase())) continue;
      result.add(BulkColor(color, price));
    }
    return result;
  }
}
