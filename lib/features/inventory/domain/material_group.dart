import 'package:nesherprints/features/inventory/domain/print_material.dart';

/// Materiales con el mismo nombre/marca (p. ej. todos los colores de una
/// marca de PLA), para no listar decenas de tarjetas sueltas.
class MaterialGroup {
  const MaterialGroup({required this.name, required this.materials});

  final String name;
  final List<PrintMaterial> materials;

  /// Precio por kilo habitual del grupo (el más repetido; a igualdad, el
  /// primero), para copiar el perfil al añadir más colores.
  double get commonPrice {
    final counts = <double, int>{};
    for (final m in materials) {
      counts[m.costPerKg] = (counts[m.costPerKg] ?? 0) + 1;
    }
    var best = materials.first.costPerKg;
    var bestCount = 0;
    counts.forEach((price, n) {
      if (n > bestCount) {
        best = price;
        bestCount = n;
      }
    });
    return best;
  }

  /// Stock sumado (un stock negativo cuenta como 0).
  double get totalGrams =>
      materials.fold(0.0, (a, m) => a + (m.stockGrams > 0 ? m.stockGrams : 0));

  bool get hasStock => materials.any((m) => m.stockGrams > 0);

  /// Agrupa por nombre (sin distinguir mayúsculas), por orden alfabético;
  /// dentro de un grupo, por color.
  static List<MaterialGroup> group(Iterable<PrintMaterial> materials) {
    final byName = <String, List<PrintMaterial>>{};
    final names = <String, String>{};
    for (final m in materials) {
      final key = m.name.trim().toLowerCase();
      names.putIfAbsent(key, () => m.name.trim());
      byName.putIfAbsent(key, () => []).add(m);
    }
    final groups = [
      for (final e in byName.entries)
        MaterialGroup(
          name: names[e.key]!,
          materials: [...e.value]
            ..sort(
              (a, b) => a.color.toLowerCase().compareTo(b.color.toLowerCase()),
            ),
        ),
    ];
    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }
}
