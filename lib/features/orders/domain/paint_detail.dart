/// Nivel de detalle de la pintura de un pedido. Sustituye al nº de colores del
/// Excel: más detalle = más material de pintura (el trabajo se mide en horas).
///
/// [dbValue] es el texto guardado en `orders.paint_detail`.
enum PaintDetail {
  /// 4 colores o menos.
  few('few'),

  /// De 5 a 10 colores.
  normal('normal'),

  /// Más de 10 colores.
  many('many');

  const PaintDetail(this.dbValue);

  final String dbValue;

  /// Valores desconocidos se tratan como [normal].
  static PaintDetail fromDb(String? value) => values.firstWhere(
    (d) => d.dbValue == value,
    orElse: () => PaintDetail.normal,
  );

  /// Modo que corresponde a un nº de colores (columna `colores` del Excel).
  /// 4 o menos → pocos; hasta 10 → normal; más de 10 → muchos.
  static PaintDetail fromColorCount(double colors) {
    if (colors <= 4) return few;
    if (colors <= 10) return normal;
    return many;
  }
}
