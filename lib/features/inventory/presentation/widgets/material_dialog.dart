import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';

/// Alta/edición de un material. Devuelve el material con [onSave].
class MaterialDialog extends StatefulWidget {
  const MaterialDialog({super.key, required this.onSave, this.initialMaterial});

  final ValueChanged<PrintMaterial> onSave;
  final PrintMaterial? initialMaterial;

  @override
  State<MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<MaterialDialog> {
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

  void _save() {
    widget.onSave(
      PrintMaterial(
        id: widget.initialMaterial?.id,
        kind: _kind,
        name: _nameController.text,
        color: _colorController.text,
        costPerKg: parseDecimal(_costController.text),
        stockGrams: parseDecimal(_stockController.text),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.initialMaterial == null
            ? AppStrings.addMaterial
            : AppStrings.editMaterial,
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MaterialKind>(
                initialValue: _kind,
                decoration: const InputDecoration(
                  labelText: AppStrings.materialTypeLabel,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: MaterialKind.filament,
                    child: Text(AppStrings.materialTypeFilament),
                  ),
                  DropdownMenuItem(
                    value: MaterialKind.resin,
                    child: Text(AppStrings.materialTypeResin),
                  ),
                ],
                onChanged: (v) => setState(() => _kind = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.materialNameLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: AppStrings.materialColorLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.materialCostPerKg,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: decimalKeyboard,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.materialStockLabel,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: decimalKeyboard,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          style: AppButtonStyles.primary,
          onPressed: _save,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
