import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_kind_chip.dart';

/// Alta/edición de un material. Devuelve el material con [onSave].
class MaterialDialog extends StatefulWidget {
  const MaterialDialog({super.key, required this.onSave, this.initialMaterial});

  final ValueChanged<PrintMaterial> onSave;
  final PrintMaterial? initialMaterial;

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

  @override
  void initState() {
    super.initState();
    final m = widget.initialMaterial;
    _kind = m?.kind ?? MaterialKind.filament;
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
    _colorController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) =>
      (value ?? '').trim().isEmpty ? AppStrings.materialNameRequired : null;

  String? _validateCost(String? value) => parseDecimal(value, fallback: -1) < 0
      ? AppStrings.materialCostInvalid
      : null;

  String? _validateStock(String? value) => parseDecimal(value, fallback: -1) < 0
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
        costPerKg: parseDecimal(_costController.text),
        stockGrams: parseDecimal(_stockController.text),
      ),
    );
    Navigator.pop(context);
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
            TextFormField(
              controller: _nameController,
              validator: _validateName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.materialNameLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _colorController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.materialColorLabel,
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
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: AppStrings.materialCostPerKg,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    validator: _validateStock,
                    keyboardType: decimalKeyboard,
                    inputFormatters: decimalInputFormatters,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: AppStrings.materialStockLabel,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
