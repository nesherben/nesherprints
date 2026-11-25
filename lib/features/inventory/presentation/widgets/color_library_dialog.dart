import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/bambu_catalog_dialog.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/color_picker_dialog.dart';

/// Gestión de la biblioteca de colores: añadir, cambiar o borrar cualquier
/// color, también los que vienen de serie.
class ColorLibraryDialog extends StatefulWidget {
  const ColorLibraryDialog({
    super.key,
    required this.initial,
    this.shelfColors = const [],
  });

  final ColorLibrary initial;

  /// Colores (nombre, RGB) de los filamentos de la estantería, para traerlos
  /// a la biblioteca de un toque.
  final List<(String, int)> shelfColors;

  @override
  State<ColorLibraryDialog> createState() => _ColorLibraryDialogState();
}

class _ColorLibraryDialogState extends State<ColorLibraryDialog> {
  late ColorLibrary _library = widget.initial;

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      final fresh = await ServiceLocator.colors.load();
      if (!mounted) return;
      setState(() => _library = fresh);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
    }
  }

  Future<void> _importBambu() async {
    final colors = await showDialog<List<LibraryColor>>(
      context: context,
      builder: (_) => BambuCatalogDialog(library: _library),
    );
    if (colors == null || !mounted) return;
    await _run(() async {
      for (final c in colors) {
        await ServiceLocator.colors.addIfMissing(c.name, c.rgb);
      }
    });
    if (!mounted) return;
    AppFeedback.success(context, AppStrings.bambuImported(colors.length));
  }

  Future<void> _edit([LibraryColor? color]) async {
    final result = await showDialog<LibraryColor>(
      context: context,
      builder: (_) => _ColorEditDialog(initial: color),
    );
    if (result == null || !mounted) return;
    await _run(
      () => color == null
          ? ServiceLocator.colors.add(result.name, result.rgb)
          : ServiceLocator.colors.update(color.id!, result.name, result.rgb),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _library.entries;
    return AppDialogFrame(
      title: AppStrings.libraryManageTitle,
      subtitle: AppStrings.libraryManageSubtitle,
      icon: Icons.palette_outlined,
      width: 600,
      footerLeading: Wrap(
        spacing: AppSpacing.sm,
        children: [
          TextButton.icon(
            onPressed: () => _run(ServiceLocator.colors.restoreBasics),
            icon: const Icon(Icons.restore, size: 18),
            label: const Text(AppStrings.restoreBasics),
          ),
          TextButton.icon(
            onPressed: _importBambu,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: const Text(AppStrings.bambuCatalogButton),
          ),
          if (widget.shelfColors.isNotEmpty)
            TextButton.icon(
              onPressed: () => _run(() async {
                for (final (name, rgb) in widget.shelfColors) {
                  await ServiceLocator.colors.addIfMissing(name, rgb);
                }
              }),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text(AppStrings.importShelfColors),
            ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.close),
        ),
        ElevatedButton.icon(
          onPressed: _edit,
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.newColor),
        ),
      ],
      child: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  AppStrings.libraryEmpty,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.muted,
                ),
              ),
            )
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in entries)
                  _ColorTile(
                    color: c,
                    onEdit: () => _edit(c),
                    onDelete: () =>
                        _run(() => ServiceLocator.colors.delete(c.id!)),
                  ),
              ],
            ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final LibraryColor color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onEdit,
        child: Container(
          width: 176,
          padding: const EdgeInsets.only(left: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Color(0xFF000000 | color.rgb),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  color.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: AppStrings.deleteColorTooltip(color.name),
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                color: AppColors.textMuted,
                icon: const Icon(Icons.close),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alta o edición de un color: nombre y RGB.
class _ColorEditDialog extends StatefulWidget {
  const _ColorEditDialog({this.initial});

  final LibraryColor? initial;

  @override
  State<_ColorEditDialog> createState() => _ColorEditDialogState();
}

class _ColorEditDialogState extends State<_ColorEditDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late int _rgb = widget.initial?.rgb ?? 0x3B82F6;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => ColorPickerDialog(initial: _rgb),
    );
    if (picked == null || !mounted) return;
    setState(() => _rgb = picked);
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(context, LibraryColor(_name.text.trim(), _rgb));
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: widget.initial == null
          ? AppStrings.newColor
          : AppStrings.editColor,
      icon: Icons.palette_outlined,
      width: 420,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _name,
          builder: (_, value, _) => ElevatedButton(
            onPressed: value.text.trim().isEmpty ? null : _save,
            child: const Text(AppStrings.save),
          ),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              autofocus: true,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: AppStrings.colorNameLabel,
                prefixIcon: Icon(Icons.label_outline, size: 20),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Tooltip(
            message: AppStrings.pickColorTooltip,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: _pick,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0xFF000000 | _rgb),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.colorize,
                  size: 20,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
