import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/utils/number_utils.dart';

/// Pieza/extra en inventario (llaveros, clickers, imanes…) que se puede
/// añadir a un pedido.
class Extra {
  const Extra({
    this.id,
    required this.name,
    required this.unitPrice,
    this.stock = 0,
    this.unit = '',
  });

  final int? id;
  final String name;

  /// Precio (coste) por unidad en €. Se recalcula como media ponderada al
  /// sumar stock.
  final double unitPrice;

  /// Unidades disponibles. Puede quedar negativo si se usan más de las que hay.
  final int stock;

  /// Unidad de medida (no editable desde la UI; se conserva).
  final String unit;

  factory Extra.fromMap(Map<String, Object?> map) => Extra(
    id: map[ExtrasTable.id] as int?,
    name: map[ExtrasTable.extraName] as String? ?? '',
    unitPrice: asDouble(map[ExtrasTable.price]),
    stock: (map[ExtrasTable.stock] as int?) ?? 0,
    unit: map[ExtrasTable.unit] as String? ?? '',
  );

  Map<String, Object?> toMap() => {
    if (id != null) ExtrasTable.id: id,
    ExtrasTable.extraName: name,
    ExtrasTable.price: unitPrice,
    ExtrasTable.stock: stock,
    ExtrasTable.unit: unit,
  };
}

/// Cálculos de precio de las piezas.
class ExtraPricing {
  ExtraPricing._();

  /// Precio unitario de un paquete: total / unidades (o el total si no hay
  /// unidades).
  static double unitPriceFromPackage({
    required double totalPrice,
    required int units,
  }) => units > 0 ? totalPrice / units : totalPrice;

  /// Total del paquete mostrado al editar: precio unitario × stock (o × 1 si
  /// no hay stock).
  static double packageTotal(Extra extra) =>
      extra.unitPrice * (extra.stock > 0 ? extra.stock : 1);

  /// Nuevo precio unitario al sumar stock: media ponderada entre el valor
  /// actual del stock y lo comprado. Si el stock resultante es ≤ 0 se
  /// mantiene el precio actual.
  static double weightedUnitPrice({
    required int currentStock,
    required double currentUnitPrice,
    required int addedUnits,
    required double addedTotal,
  }) {
    final newStock = currentStock + addedUnits;
    if (newStock <= 0) return currentUnitPrice;
    return (currentUnitPrice * currentStock + addedTotal) / newStock;
  }
}
