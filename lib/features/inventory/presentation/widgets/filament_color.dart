import 'package:flutter/material.dart';

import 'package:nesherprints/features/inventory/domain/color_library.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_kind_chip.dart';

/// Color con el que se pinta la bobina de un filamento: el que se eligió o,
/// si no, el deducido del texto del color o del nombre («Rojo», «PLA negro»…).
Color filamentColorFor(PrintMaterial material) {
  final rgb =
      material.colorRgb ??
      ColorLibrary.defaults().guess('${material.color} ${material.name}');
  if (rgb == null) return MaterialKind.filament.tint;
  return Color(0xFF000000 | rgb);
}
