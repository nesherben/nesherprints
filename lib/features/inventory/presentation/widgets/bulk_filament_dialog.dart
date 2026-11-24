import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/features/inventory/domain/bulk_filaments.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_kind_chip.dart';

/// Alta de muchos filamentos de golpe: marca y precio una sola vez, y los
/// colores como etiquetas. Se añaden escribiendo y pulsando Enter, pegando una
/// lista o tocando los colores de la biblioteca.
class BulkFilamentDialog extends StatefulWidget {
  const BulkFilamentDialog({super.key, required this.onSave, this.library});

  final ValueChanged<List<PrintMaterial>> onSave;

  /// Colores ya conocidos: se ofrecen para añadir con un toque y se aplican
  /// por nombre a los nuevos.
  final ColorLibrary? library;

  @override
  State<BulkFilamentDialog> createState() => _BulkFilamentDialogState();
}

class _BulkFilamentDialogState extends State<BulkFilamentDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _colorController = TextEditingController();
  final _colorFocus = FocusNode();

  /// Colores ya confirmados como etiquetas.
  final List<BulkColor> _picked = [];

  ColorLibrary get _library => widget.library ?? ColorLibrary.defaults();

  double get _price => parseDecimal(_priceController.text, fallback: -1);

  /// Etiquetas más lo que haya a medio escribir.
  List<BulkColor> get _all =>
      _merge([..._picked, ...BulkFilaments.parse(_colorController.text)]);

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _price >= 0 && _all.isNotEmpty;

  static List<BulkColor> _merge(List<BulkColor> colors) {
    final seen = <String>{};
    return [
      for (final c in colors)
        if (seen.add(c.color.toLowerCase())) c,
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _colorController.dispose();
    _colorFocus.dispose();
    super.dispose();
  }

  /// Al escribir una línea nueva (Enter) o pegar una lista, lo completo pasa a
  /// etiquetas y queda en el campo solo lo que falta por terminar.
  void _onColorsChanged(String text) {
    if (text.contains('\n') || text.contains(';')) {
      final parts = text.split(RegExp(r'[\n;]'));
      final rest = parts.removeLast();
      setState(() {
        final merged = _merge([
          ..._picked,
          ...BulkFilaments.parse(parts.join('\n')),
        ]);
        _picked
          ..clear()
          ..addAll(merged);
      });
      _colorController.value = TextEditingValue(
        text: rest,
        selection: TextSelection.collapsed(offset: rest.length),
      );
      return;
    }
    setState(() {});
  }

  void _addFromLibrary(LibraryColor c) {
    setState(() => _picked.add(BulkColor(c.name, null)));
    _colorFocus.requestFocus();
  }

  void _remove(BulkColor c) => setState(() => _picked.remove(c));

  void _save() {
    if (!_canSave) return;
    final name = _nameController.text.trim();
    widget.onSave([
      for (final c in _all)
        PrintMaterial(
          kind: MaterialKind.filament,
          name: name,
          color: c.color,
          costPerKg: c.pricePerKg ?? _price,
          stockGrams: 0,
          colorRgb: _library.rgbFor(c.color) ?? _library.guess(c.color),
        ),
    ]);
    Navigator.pop(context);
  }

  Widget _tag(BulkColor c) {
    final rgb = _library.rgbFor(c.color) ?? _library.guess(c.color);
    return InputChip(
      avatar: CircleAvatar(
        radius: 9,
        backgroundColor: rgb == null
            ? AppColors.surfaceHigh
            : Color(0xFF000000 | rgb),
      ),
      label: Text(
        c.pricePerKg == null
            ? c.color
            : '${c.color} · ${c.pricePerKg!.toStringAsFixed(2)} €',
      ),
      deleteButtonTooltipMessage: AppStrings.bulkRemoveTooltip(c.color),
      onDeleted: () => _remove(c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final taken = {for (final c in all) c.color.toLowerCase()};
    final available = [
      for (final c in _library.entries)
        if (!taken.contains(c.name.toLowerCase())) c,
    ];
    return AppDialogFrame(
      title: AppStrings.bulkTitle,
      subtitle: AppStrings.bulkSubtitle,
      icon: MaterialKind.filament.icon,
      iconColor: MaterialKind.filament.textTint,
      width: 560,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _canSave ? _save : null,
          child: Text(AppStrings.bulkCreate(all.length)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: AppStrings.materialNameLabel,
                    prefixIcon: Icon(Icons.label_outline, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceController,
                  keyboardType: decimalKeyboard,
                  inputFormatters: decimalInputFormatters,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: AppStrings.bulkDefaultPrice,
                    prefixIcon: Icon(Icons.euro, size: 20),
                    suffixText: '€/kg',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _colorController,
            focusNode: _colorFocus,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            onChanged: _onColorsChanged,
            decoration: const InputDecoration(
              labelText: AppStrings.bulkColorsLabel,
              hintText: AppStrings.bulkColorsHint,
              prefixIcon: Icon(Icons.palette_outlined, size: 20),
            ),
          ),
          if (_picked.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final c in _picked) _tag(c)],
            ),
          ],
          if (available.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text(
              AppStrings.bulkLibraryHint,
              style: AppTextStyles.overline,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in available)
                  ActionChip(
                    avatar: CircleAvatar(
                      radius: 9,
                      backgroundColor: Color(0xFF000000 | c.rgb),
                    ),
                    label: Text(c.name),
                    onPressed: () => _addFromLibrary(c),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
