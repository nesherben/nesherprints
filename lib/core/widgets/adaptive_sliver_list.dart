import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/responsive.dart';

/// Lista de filas compactas que aprovecha el ancho: una columna en pantallas
/// estrechas (las filas pueden crecer en alto) y, en anchas, una rejilla de
/// columnas de [columnWidth] como máximo con filas de alto fijo [rowHeight].
class AdaptiveSliverList extends StatelessWidget {
  const AdaptiveSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.rowHeight,
    this.columnWidth = 640,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Alto fijo de cada fila cuando se muestra en rejilla.
  final double rowHeight;

  /// Ancho máximo de cada columna en la rejilla.
  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    if (context.isCompact) {
      return SliverList.separated(
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: itemBuilder,
      );
    }
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: columnWidth,
        mainAxisExtent: rowHeight,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.sm,
      ),
      delegate: SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
    );
  }
}
