/// Un color de la biblioteca: nombre y valor RGB (0xRRGGBB).
class LibraryColor {
  const LibraryColor(this.name, this.rgb, {this.id});

  final int? id;
  final String name;
  final int rgb;
}

/// Biblioteca de colores de filamento (lógica pura). La mantiene el usuario:
/// parte de unos básicos que puede borrar o ampliar, y cada color nuevo que
/// da de alta en un filamento se añade solo.
class ColorLibrary {
  ColorLibrary._(this.entries);

  /// Colores de la biblioteca, sin repetir nombre (sin distinguir mayúsculas).
  final List<LibraryColor> entries;

  /// Colores básicos con los que arranca la biblioteca.
  static const List<LibraryColor> basics = [
    LibraryColor('Negro', 0x2B2B2F),
    LibraryColor('Blanco', 0xF2F2F2),
    LibraryColor('Gris', 0x8A8F98),
    LibraryColor('Plata', 0xC0C4CC),
    LibraryColor('Rojo', 0xE5484D),
    LibraryColor('Rosa', 0xF472B6),
    LibraryColor('Naranja', 0xF97316),
    LibraryColor('Amarillo', 0xFACC15),
    LibraryColor('Oro', 0xD4A72C),
    LibraryColor('Verde', 0x22C55E),
    LibraryColor('Turquesa', 0x14B8A6),
    LibraryColor('Cian', 0x22D3EE),
    LibraryColor('Azul', 0x3B82F6),
    LibraryColor('Morado', 0x8B5CF6),
    LibraryColor('Marrón', 0x8B5E3C),
    LibraryColor('Beige', 0xE5D3B3),
  ];

  /// Biblioteca con exactamente [colors] (los repetidos por nombre se
  /// ignoran).
  factory ColorLibrary.of(Iterable<LibraryColor> colors) {
    final seen = <String>{};
    return ColorLibrary._([
      for (final c in colors)
        if (c.name.trim().isNotEmpty && seen.add(c.name.trim().toLowerCase()))
          c,
    ]);
  }

  /// Biblioteca de partida (los básicos), sin base de datos.
  factory ColorLibrary.defaults() => ColorLibrary.of(basics);

  /// RGB de un color por su nombre exacto (sin distinguir mayúsculas).
  int? rgbFor(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final e in entries) {
      if (e.name.toLowerCase() == key) return e.rgb;
    }
    return null;
  }

  /// RGB deducido de un texto libre («PLA negro mate»): el color de la
  /// biblioteca cuyo nombre aparece en él (el más largo gana).
  int? guess(String text) {
    final t = text.toLowerCase();
    LibraryColor? best;
    for (final e in entries) {
      final n = e.name.toLowerCase();
      if (n.length >= 3 &&
          t.contains(n) &&
          (best == null || n.length > best.name.length)) {
        best = e;
      }
    }
    return best?.rgb;
  }

  /// Sugerencias para lo que se va escribiendo: las que empiezan por
  /// [query] primero y después las que lo contienen. Vacío si no hay texto.
  List<LibraryColor> suggest(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final starts = <LibraryColor>[];
    final contains = <LibraryColor>[];
    for (final e in entries) {
      final n = e.name.toLowerCase();
      if (n == q) continue;
      if (n.startsWith(q)) {
        starts.add(e);
      } else if (n.contains(q)) {
        contains.add(e);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }
}
