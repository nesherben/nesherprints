import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/responsive.dart';

/// Barra de herramientas de una lista: buscador y filtros. En pantalla ancha
/// van en la misma línea (buscador a la izquierda, filtros a su lado); en
/// estrecha, apilados.
class ListToolbar extends StatelessWidget {
  const ListToolbar({super.key, required this.search, required this.filters});

  final Widget search;
  final Widget filters;

  /// Ancho del buscador cuando comparte línea con los filtros.
  static const double searchWidth = 380;

  @override
  Widget build(BuildContext context) {
    if (context.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          search,
          const SizedBox(height: AppSpacing.md),
          filters,
        ],
      );
    }
    return Row(
      children: [
        SizedBox(width: searchWidth, child: search),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: filters),
        ),
      ],
    );
  }
}
