import 'package:flutter/widgets.dart';

import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';

/// Placa editable dentro del formulario de pedido.
class PlateDraft {
  PlateDraft({
    this.id,
    required this.name,
    this.grams = 0,
    this.minutes = 0,
    this.materialId,
    this.status = PlateStatus.pending,
  });

  factory PlateDraft.fromPlate(OrderPlate plate) => PlateDraft(
    id: plate.id,
    name: plate.name,
    grams: plate.grams,
    minutes: plate.minutes,
    materialId: plate.materialId,
    status: plate.status,
  );

  /// Identidad estable en la lista (para que los campos no se mezclen al
  /// borrar una placa).
  final Key key = UniqueKey();

  final int? id;
  String name;
  double grams;
  double minutes;
  int? materialId;
  final PlateStatus status;

  OrderPlate toPlate() => OrderPlate(
    id: id,
    name: name,
    grams: grams,
    minutes: minutes,
    materialId: materialId,
    status: status,
  );

  PricingPlate toPricing() =>
      PricingPlate(materialId: materialId, grams: grams, minutes: minutes);
}
