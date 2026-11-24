import 'dart:math' as math;

import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';

/// Material del que no queda stock suficiente para completar un pedido.
class StockShortage {
  const StockShortage({
    required this.materialName,
    required this.neededGrams,
    required this.availableGrams,
  });

  final String materialName;

  /// Lo que se descontará al completar (gramos de placas menos la merma ya
  /// registrada).
  final double neededGrams;

  /// Lo que hay ahora en el inventario.
  final double availableGrams;
}

/// Comprobación de stock previa a completar un pedido (lógica pura).
class StockCheck {
  StockCheck._();

  /// Materiales cuyo stock quedaría en negativo al completar el pedido con
  /// [plates]. [wasteByMaterial] es la merma ya registrada (ya descontada).
  static List<StockShortage> shortages({
    required List<OrderPlate> plates,
    required Map<int, double> wasteByMaterial,
    required List<PrintMaterial> materials,
  }) {
    final needed = <int, double>{};
    for (final p in plates) {
      final id = p.materialId;
      if (id == null) continue;
      needed[id] = (needed[id] ?? 0) + p.grams;
    }
    final result = <StockShortage>[];
    for (final m in materials) {
      // El filamento no lleva el stock al día: no hay nada que avisar.
      if (!m.tracksStock) continue;
      final toDeduct = math.max(
        0.0,
        (needed[m.id] ?? 0) - (wasteByMaterial[m.id] ?? 0),
      );
      if (toDeduct > m.stockGrams) {
        result.add(
          StockShortage(
            materialName: m.name,
            neededGrams: toDeduct,
            availableGrams: m.stockGrams,
          ),
        );
      }
    }
    return result;
  }
}
