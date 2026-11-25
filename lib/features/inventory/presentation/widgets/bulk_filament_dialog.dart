import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/features/inventory/domain/bambu_catalog.dart';
import 'package:nesherprints/features/inventory/domain/bulk_filaments.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_kind_chip.dart';

/// Perfil de filamento que se puede copiar: nombre y precio por kilo.
class FilamentProfile {
  const FilamentProfile(this.name, this.pricePerKg, {this.type});

  final String name;
  final double? pricePerKg;

  /// Tipo del catálogo Bambu Lab, si viene de él.
  final BambuType? type;
}

/// Alta de muchos filamentos de golpe: marca y precio una sola vez, y los
/// colores como etiquetas. Se añaden escribiendo y pulsando Enter, pegando una
/// lista o tocando los colores de la biblioteca.
class BulkFilamentDialog extends StatefulWidget {
  const BulkFilamentDialog({
    super.key,
    required this.onSave,
    this.library,
    this.profiles = const [],
    this.initialProfile,
  });

  final ValueChanged<List<PrintMaterial>> onSave;

  /// Perfiles ya existentes, para copiar nombre y precio con un toque.
  final List<FilamentProfile> profiles;

  /// Perfil con el que se abre el diálogo (desde «Añadir color» de una marca).
  final FilamentProfile? initialProfile;

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
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    if (p != null) _applyProfile(p, focusColors: true);
  }

  /// Copia un perfil: nombre y precio; el cursor pasa a los colores.
  void _applyProfile(FilamentProfile p, {bool focusColors = false}) {
    _nameController.text = p.name;
    final price = p.pricePerKg;
    if (price != null) _priceController.text = formatFieldDecimal(price);
    if (focusColors) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _colorFocus.requestFocus();
      });
    }
  }

  /// Tipo Bambu Lab que indica el nombre (sus colores se ofrecen primero).
  BambuType? get _type => BambuCatalog.typeOf(_nameController.text);

  /// RGB de un color: el del catálogo del tipo, y si no el de la biblioteca.
  int? _rgbOf(String name) {
    final key = name.trim().toLowerCase();
    for (final c in _type?.colors ?? const <LibraryColor>[]) {
      if (c.name.toLowerCase() == key) return c.rgb;
    }
    return _library.rgbFor(name) ?? _library.guess(name);
  }

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
    _nameFocus.dispose();
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
          colorRgb: _rgbOf(c.color),
        ),
    ]);
    Navigator.pop(context);
  }

  /// Nombre con autocompletado: perfiles que ya tienes y tipos Bambu Lab.
  Widget _buildNameField() {
    return RawAutocomplete<FilamentProfile>(
      textEditingController: _nameController,
      focusNode: _nameFocus,
      displayStringForOption: (p) => p.name,
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        if (q.isEmpty) return const [];
        return [
          for (final p in widget.profiles)
            if (p.name.toLowerCase().contains(q) && p.name.toLowerCase() != q)
              p,
          for (final t in BambuCatalog.suggestTypes(v.text))
            FilamentProfile(t.materialName, null, type: t),
        ].take(10).toList();
      },
      onSelected: (p) => setState(() => _applyProfile(p, focusColors: true)),
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        autofocus: widget.initialProfile == null,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: AppStrings.materialNameLabel,
          prefixIcon: Icon(Icons.label_outline, size: 20),
        ),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final p in options)
                  ListTile(
                    dense: true,
                    title: Text(p.name),
                    subtitle: Text(
                      p.type != null
                          ? AppStrings.bambuColorsCount(p.type!.colors.length)
                          : '${formatEuro(p.pricePerKg ?? 0)}/kg',
                      style: AppTextStyles.mutedSmall,
                    ),
                    onTap: () => onSelected(p),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(BulkColor c) {
    final rgb = _rgbOf(c.color);
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
    // Con un tipo Bambu Lab se ofrecen sus colores; si no, la biblioteca.
    final type = _type;
    final source = type?.colors ?? _library.entries;
    final available = [
      for (final c in source)
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
              Expanded(flex: 3, child: _buildNameField()),
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
          if (widget.profiles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(AppStrings.copyProfile, style: AppTextStyles.overline),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final p in widget.profiles.take(8))
                  ActionChip(
                    avatar: const Icon(Icons.copy_outlined, size: 14),
                    label: Text(
                      p.pricePerKg == null
                          ? p.name
                          : '${p.name} · ${formatEuro(p.pricePerKg!)}/kg',
                    ),
                    onPressed: () =>
                        setState(() => _applyProfile(p, focusColors: true)),
                  ),
              ],
            ),
          ],
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
