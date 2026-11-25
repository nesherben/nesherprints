import 'package:nesherprints/core/constants/app_constants.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/utils/number_utils.dart';

/// Tipo de material. [dbValue] es el valor guardado en `materials.type`.
enum MaterialKind {
  filament('filament'),
  resin('resin');

  const MaterialKind(this.dbValue);

  final String dbValue;

  /// Cualquier valor distinto de `resin` se trata como filamento.
  static MaterialKind fromDb(String? value) =>
      value == resin.dbValue ? resin : filament;
}

/// Material de impresión en inventario (bobina de filamento o resina).
///
/// Se llama `PrintMaterial` para no chocar con `Material` de Flutter.
class PrintMaterial {
  const PrintMaterial({
    this.id,
    required this.kind,
    required this.name,
    required this.color,
    required this.costPerKg,
    required this.stockGrams,
    this.colorRgb,
  });

  final int? id;
  final MaterialKind kind;
  final String name;
  final String color;

  /// Coste en € por kilo (o litro, en resina).
  final double costPerKg;

  /// Stock restante en gramos (o ml).
  final double stockGrams;

  /// Color de la bobina (0xRRGGBB); `null` si no se ha elegido.
  final int? colorRgb;

  /// Copia con otro precio por kilo.
  PrintMaterial withCost(double cost) => PrintMaterial(
    id: id,
    kind: kind,
    name: name,
    color: color,
    costPerKg: cost,
    stockGrams: stockGrams,
    colorRgb: colorRgb,
  );

  /// Solo la resina lleva el stock al día; en filamento el usuario sabe lo que
  /// le queda y la app solo guarda el color y su precio.
  bool get tracksStock => kind == MaterialKind.resin;

  /// Sin stock (o en negativo).
  bool get isOutOfStock => stockGrams <= 0;

  /// Queda poco pero no se ha agotado.
  bool get isLowStock =>
      stockGrams > 0 && stockGrams < InventoryRules.lowStockGrams;

  factory PrintMaterial.fromMap(Map<String, Object?> map) => PrintMaterial(
    id: map[MaterialsTable.id] as int?,
    kind: MaterialKind.fromDb(map[MaterialsTable.type] as String?),
    name: map[MaterialsTable.materialName] as String? ?? '',
    color: map[MaterialsTable.color] as String? ?? '',
    costPerKg: asDouble(map[MaterialsTable.costPerKg]),
    stockGrams: asDouble(map[MaterialsTable.stockGrams]),
    colorRgb: (map[MaterialsTable.colorRgb] as num?)?.toInt(),
  );

  Map<String, Object?> toMap() => {
    if (id != null) MaterialsTable.id: id,
    MaterialsTable.type: kind.dbValue,
    MaterialsTable.materialName: name,
    MaterialsTable.color: color,
    MaterialsTable.costPerKg: costPerKg,
    MaterialsTable.stockGrams: stockGrams,
    MaterialsTable.colorRgb: colorRgb,
  };
}
