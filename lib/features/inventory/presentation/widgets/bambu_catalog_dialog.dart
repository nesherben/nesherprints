import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/features/inventory/domain/bambu_catalog.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';

/// Elegir qué tipos del catálogo Bambu Lab importar a la biblioteca. Devuelve
/// los colores a añadir (ya sin repetidos) o `null` si se cancela.
class BambuCatalogDialog extends StatefulWidget {
  const BambuCatalogDialog({super.key, required this.library});

  final ColorLibrary library;

  @override
  State<BambuCatalogDialog> createState() => _BambuCatalogDialogState();
}

class _BambuCatalogDialogState extends State<BambuCatalogDialog> {
  final Set<String> _selected = {};

  List<BambuType> get _chosen => [
    for (final t in BambuCatalog.types)
      if (_selected.contains(t.name)) t,
  ];

  @override
  Widget build(BuildContext context) {
    final toAdd = BambuCatalog.toImport(_chosen, widget.library);
    final all = _selected.length == BambuCatalog.types.length;
    return AppDialogFrame(
      title: AppStrings.bambuCatalogTitle,
      subtitle: AppStrings.bambuCatalogSubtitle(
        BambuCatalog.types.length,
        BambuCatalog.colorCount,
      ),
      icon: Icons.inventory_2_outlined,
      width: 600,
      footerLeading: TextButton(
        onPressed: () => setState(() {
          if (all) {
            _selected.clear();
          } else {
            _selected.addAll(BambuCatalog.types.map((t) => t.name));
          }
        }),
        child: Text(all ? AppStrings.selectNone : AppStrings.selectAll),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton.icon(
          onPressed: toAdd.isEmpty ? null : () => Navigator.pop(context, toAdd),
          icon: const Icon(Icons.download_outlined),
          label: Text(AppStrings.bambuImportCount(toAdd.length)),
        ),
      ],
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final t in BambuCatalog.types)
            FilterChip(
              selected: _selected.contains(t.name),
              onSelected: (on) => setState(
                () => on ? _selected.add(t.name) : _selected.remove(t.name),
              ),
              label: Text('${t.name} · ${t.colors.length}'),
              side: BorderSide(color: AppColors.border),
            ),
        ],
      ),
    );
  }
}
