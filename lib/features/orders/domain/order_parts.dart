import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Placa de impresión de un pedido (fila de `order_plates`).
class OrderPlate {
  const OrderPlate({
    this.id,
    required this.name,
    required this.grams,
    required this.minutes,
    required this.materialId,
    this.status = PlateStatus.pending,
  });

  final int? id;
  final String name;
  final double grams;
  final double minutes;
  final int? materialId;
  final PlateStatus status;

  factory OrderPlate.fromMap(Map<String, Object?> map) => OrderPlate(
    id: map[OrderPlatesTable.id] as int?,
    name: map[OrderPlatesTable.plateName] as String? ?? '',
    grams: asDouble(map[OrderPlatesTable.grams]),
    minutes: asDouble(map[OrderPlatesTable.minutes]),
    materialId: map[OrderPlatesTable.materialId] as int?,
    status: PlateStatus.fromDb(map[OrderPlatesTable.status] as String?),
  );

  /// Fila para insertar. Conserva el `id` si la placa ya existía.
  Map<String, Object?> toMap(int orderId) => {
    if (id != null) OrderPlatesTable.id: id,
    OrderPlatesTable.orderId: orderId,
    OrderPlatesTable.plateName: name,
    OrderPlatesTable.grams: grams,
    OrderPlatesTable.minutes: minutes,
    OrderPlatesTable.materialId: materialId,
    OrderPlatesTable.status: status.dbValue,
  };
}

/// Pieza extra añadida a un pedido: id de la pieza y cantidad.
class OrderExtraLine {
  const OrderExtraLine({
    required this.extraId,
    required this.quantity,
    this.unitPrice,
  });

  final int extraId;
  final int quantity;

  /// Precio unitario registrado al añadir la pieza al pedido (`null` en una
  /// línea nueva: se tomará el precio actual de la pieza).
  final double? unitPrice;
}

/// Merma registrada (fila de `order_waste`).
class WasteRecord {
  const WasteRecord({
    this.id,
    required this.orderId,
    this.materialId,
    required this.grams,
    this.reason = '',
    this.date,
  });

  final int? id;
  final int orderId;

  /// `null` si la merma era de un material histórico ya retirado.
  final int? materialId;
  final double grams;
  final String reason;
  final String? date;

  factory WasteRecord.fromMap(Map<String, Object?> map) => WasteRecord(
    id: map[OrderWasteTable.id] as int?,
    orderId: map[OrderWasteTable.orderId] as int,
    materialId: map[OrderWasteTable.materialId] as int?,
    grams: asDouble(map[OrderWasteTable.gramsWasted]),
    reason: map[OrderWasteTable.reason] as String? ?? '',
    date: map[OrderWasteTable.date] as String?,
  );
}

/// Consumo de material de la tabla heredada `order_items`.
class LegacyOrderItem {
  const LegacyOrderItem({
    required this.orderId,
    required this.materialId,
    required this.grams,
  });

  final int orderId;
  final int materialId;
  final double grams;

  factory LegacyOrderItem.fromMap(Map<String, Object?> map) => LegacyOrderItem(
    orderId: map[OrderItemsTable.orderId] as int,
    materialId: map[OrderItemsTable.materialId] as int,
    grams: asDouble(map[OrderItemsTable.gramsUsed]),
  );
}
