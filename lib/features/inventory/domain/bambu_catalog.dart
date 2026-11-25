import 'package:nesherprints/features/inventory/domain/bambu_catalog_data.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';

/// Un tipo de filamento de Bambu Lab (PLA Basic, PETG HF…) con sus colores.
class BambuType {
  const BambuType(this.name, this.colors);

  final String name;
  final List<LibraryColor> colors;

  /// Nombre con el que se da de alta el material («Bambu Lab PLA Basic»).
  String get materialName => '${BambuCatalog.brand} $name';
}

/// Catálogo de filamentos Bambu Lab incluido en la app (lógica pura): permite
/// sugerir tipos y colores al dar de alta una bobina e importar los colores a
/// la biblioteca.
class BambuCatalog {
  BambuCatalog._();

  static const String brand = 'Bambu Lab';

  static final List<BambuType> types = [
    for (final (name, colors) in bambuCatalogData)
      BambuType(name, [for (final (c, rgb) in colors) LibraryColor(c, rgb)]),
  ];

  /// Total de colores del catálogo (con repeticiones entre tipos).
  static int get colorCount => types.fold(0, (sum, t) => sum + t.colors.length);

  /// Tipos cuyo nombre de material («Bambu Lab» + tipo) empieza por [query] o
  /// lo contiene, para autocompletar el nombre del material. Vacío si no hay texto.
  static List<BambuType> suggestTypes(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final starts = <BambuType>[];
    final contains = <BambuType>[];
    for (final t in types) {
      final n = t.materialName.toLowerCase();
      if (n == q) continue;
      if (n.startsWith(q)) {
        starts.add(t);
      } else if (n.contains(q)) {
        contains.add(t);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  /// Tipo del catálogo al que corresponde el nombre de un material (el
  /// nombre del tipo más largo contenido en él, si menciona a Bambu).
  static BambuType? typeOf(String materialName) {
    final t = materialName.toLowerCase();
    if (!t.contains('bambu')) return null;
    BambuType? best;
    for (final type in types) {
      final n = type.name.toLowerCase();
      if (t.contains(n) && (best == null || n.length > best.name.length)) {
        best = type;
      }
    }
    return best;
  }

  /// Colores de la biblioteca a añadir al importar [selected]: se salta los
  /// nombres ya existentes con el mismo RGB, y si el nombre existe con otro
  /// RGB (el mismo nombre en otro acabado) lo añade como «Nombre (Tipo)».
  static List<LibraryColor> toImport(
    Iterable<BambuType> selected,
    ColorLibrary library,
  ) {
    final taken = {
      for (final e in library.entries) e.name.trim().toLowerCase(): e.rgb,
    };
    final result = <LibraryColor>[];
    for (final type in selected) {
      for (final c in type.colors) {
        final key = c.name.toLowerCase();
        if (!taken.containsKey(key)) {
          taken[key] = c.rgb;
          result.add(c);
        } else if (taken[key] != c.rgb) {
          final alt = '${c.name} (${type.name})';
          final altKey = alt.toLowerCase();
          if (!taken.containsKey(altKey)) {
            taken[altKey] = c.rgb;
            result.add(LibraryColor(alt, c.rgb));
          }
        }
      }
    }
    return result;
  }
}
