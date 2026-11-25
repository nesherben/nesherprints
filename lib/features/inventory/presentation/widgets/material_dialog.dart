import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/features/inventory/domain/bambu_catalog.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/color_picker_dialog.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_kind_chip.dart';

/// Alta/edición de un material. Devuelve el material con [onSave].
class MaterialDialog extends StatefulWidget {
  const MaterialDialog({
    super.key,
    required this.onSave,
    this.initialMaterial,
    this.library,
  });

  final ValueChanged<PrintMaterial> onSave;
  final PrintMaterial? initialMaterial;

  /// Colores ya usados, para sugerirlos y rellenar el RGB.
  final ColorLibrary? library;

  @override
  State<MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<MaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  late MaterialKind _kind;
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  late final TextEditingController _costController;
  late final TextEditingController _stockController;
  final _colorFocus = FocusNode();
  final _nameFocus = FocusNode();

  /// RGB elegido para la bobina (filamento).
  int? _rgb;
  bool _rgbManual = false;

  ColorLibrary get _library => widget.library ?? ColorLibrary.defaults();

  @override
  void initState() {
    super.initState();
    final m = widget.initialMaterial;
    _kind = m?.kind ?? MaterialKind.filament;
    _rgb = m?.colorRgb;
    _rgbManual = m?.colorRgb != null;
    _nameController = TextEditingController(text: m?.name ?? '');
    _colorController = TextEditingController(text: m?.color ?? '');
    _costController = TextEditingController(
      text: m?.costPerKg.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: m?.stockGrams.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _colorController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _colorFocus.dispose();
    super.dispose();
  }

  String? _validateName(String? value) =>
      (value ?? '').trim().isEmpty ? AppStrings.materialNameRequired : null;

  String? _validateCost(String? value) => parseDecimal(value, fallback: -1) < 0
      ? AppStrings.materialCostInvalid
      : null;

  String? _validateStock(String? value) =>
      _kind == MaterialKind.resin && parseDecimal(value, fallback: -1) < 0
      ? AppStrings.materialStockInvalid
      : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      PrintMaterial(
        id: widget.initialMaterial?.id,
        kind: _kind,
        name: _nameController.text.trim(),
        color: _colorController.text.trim(),
        colorRgb: _kind == MaterialKind.filament
            ? (_rgb ?? _library.guess(_colorController.text))
            : null,
        costPerKg: parseDecimal(_costController.text),
        // El filamento no lleva stock: se conserva lo que hubiera.
        stockGrams: _kind == MaterialKind.resin
            ? parseDecimal(_stockController.text)
            : (widget.initialMaterial?.stockGrams ?? 0),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickColor() async {
    final current = _rgb ?? _library.guess(_colorController.text) ?? 0xF59E0B;
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => ColorPickerDialog(initial: current, library: _library),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _rgb = picked;
      _rgbManual = true;
    });
  }

  /// Si el nombre ya está en la biblioteca y no se eligió un RGB a mano, se
  /// usa el de la biblioteca.
  void _onColorTyped(String text) {
    if (_rgbManual) return;
    final known = _library.rgbFor(text);
    setState(() => _rgb = known);
  }

  /// Sugerencias de color: los del tipo Bambu Lab que indica el nombre del
  /// material (todos si no se ha escrito nada) y los de la biblioteca.
  List<LibraryColor> _colorOptions(String query) {
    final q = query.trim().toLowerCase();
    final type = BambuCatalog.typeOf(_nameController.text);
    final fromType = [
      if (type != null)
        for (final c in type.colors)
          if (q.isEmpty || c.name.toLowerCase().contains(q)) c,
    ];
    final seen = {for (final c in fromType) c.name.toLowerCase()};
    return [
      ...fromType,
      for (final c in _library.suggest(query))
        if (seen.add(c.name.toLowerCase())) c,
    ];
  }

  /// Nombre del material con sugerencias de tipos Bambu Lab.
  Widget _buildNameField() {
    return RawAutocomplete<BambuType>(
      textEditingController: _nameController,
      focusNode: _nameFocus,
      displayStringForOption: (t) => t.materialName,
      optionsBuilder: (v) => _kind == MaterialKind.filament
          ? BambuCatalog.suggestTypes(v.text)
          : const [],
      onSelected: (_) => setState(() {}),
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextFormField(
        controller: controller,
        focusNode: focus,
        validator: _validateName,
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
                for (final t in options)
                  ListTile(
                    dense: true,
                    title: Text(t.materialName),
                    subtitle: Text(
                      AppStrings.bambuColorsCount(t.colors.length),
                      style: AppTextStyles.mutedSmall,
                    ),
                    onTap: () => onSelected(t),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nombre del color con sugerencias de la biblioteca y el selector RGB.
  Widget _buildColorRow() {
    final shown = _rgb ?? _library.guess(_colorController.text);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RawAutocomplete<LibraryColor>(
            textEditingController: _colorController,
            focusNode: _colorFocus,
            displayStringForOption: (c) => c.name,
            optionsBuilder: (v) => _colorOptions(v.text),
            onSelected: (c) => setState(() {
              _rgb = c.rgb;
              _rgbManual = false;
            }),
            fieldViewBuilder: (context, controller, focus, onSubmit) =>
                TextFormField(
                  controller: controller,
                  focusNode: focus,
                  textInputAction: TextInputAction.next,
                  onChanged: _onColorTyped,
                  decoration: const InputDecoration(
                    labelText: AppStrings.materialColorLabel,
                    prefixIcon: Icon(Icons.palette_outlined, size: 20),
                  ),
                ),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 220,
                    maxWidth: 300,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final c in options)
                        ListTile(
                          dense: true,
                          leading: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Color(0xFF000000 | c.rgb),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                          title: Text(c.name),
                          onTap: () => onSelected(c),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Tooltip(
          message: AppStrings.pickColorTooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: _pickColor,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: shown == null
                    ? AppColors.surfaceHigh
                    : Color(0xFF000000 | shown),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.colorize,
                size: 20,
                color: shown == null ? AppColors.textMuted : Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialMaterial == null;
    return AppDialogFrame(
      title: isNew ? AppStrings.addMaterial : AppStrings.editMaterial,
      icon: _kind.icon,
      iconColor: _kind.textTint,
      width: 480,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.materialTypeLabel,
              style: AppTextStyles.overline,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MaterialKind>(
                showSelectedIcon: false,
                segments: [
                  for (final kind in MaterialKind.values)
                    ButtonSegment(
                      value: kind,
                      icon: Icon(kind.icon, size: 18),
                      label: Text(kind.shortLabel),
                    ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildNameField(),
            const SizedBox(height: AppSpacing.lg),
            if (_kind == MaterialKind.filament)
              _buildColorRow()
            else
              TextFormField(
                controller: _colorController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: AppStrings.materialColorLabel,
                  prefixIcon: Icon(Icons.palette_outlined, size: 20),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    validator: _validateCost,
                    keyboardType: decimalKeyboard,
                    inputFormatters: decimalInputFormatters,
                    textInputAction: _kind == MaterialKind.resin
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: _kind == MaterialKind.resin
                        ? null
                        : (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: AppStrings.materialCostPerKg,
                      prefixIcon: Icon(Icons.euro, size: 20),
                      suffixText: '€/kg',
                    ),
                  ),
                ),
                // Solo la resina lleva los gramos al día.
                if (_kind == MaterialKind.resin) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      validator: _validateStock,
                      keyboardType: decimalKeyboard,
                      inputFormatters: decimalInputFormatters,
                      onFieldSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        labelText: AppStrings.resinCurrentStock,
                        prefixIcon: Icon(Icons.scale_outlined, size: 20),
                        suffixText: 'g',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
