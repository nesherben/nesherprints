import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/number_utils.dart';
import '../../core/strings.dart';

class MaterialDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialMaterial;

  const MaterialDialog({super.key, required this.onSave, this.initialMaterial});

  @override
  State<MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<MaterialDialog> {
  late String _selectedType;
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final mat = widget.initialMaterial;
    _selectedType = mat?['type'] ?? 'filament';
    _nameController.text = mat?['name'] ?? '';
    _colorController.text = mat?['color'] ?? '';
    _costController.text = (mat?['cost_per_kg'] ?? '').toString();
    _stockController.text = (mat?['stock_g'] ?? '').toString();
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
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: AppStrings.materialTypeLabel,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'filament',
                    child: Text(AppStrings.materialTypeFilament),
                  ),
                  DropdownMenuItem(
                    value: 'resin',
                    child: Text(AppStrings.materialTypeResin),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
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
                      keyboardType: TextInputType.number,
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
                      keyboardType: TextInputType.number,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
          ),
          onPressed: () {
            widget.onSave({
              'id': widget.initialMaterial?['id'],
              'type': _selectedType,
              'name': _nameController.text,
              'color': _colorController.text,
              'cost_per_kg': parseDecimal(_costController.text),
              'stock_g': parseDecimal(_stockController.text),
            });
            Navigator.pop(context);
          },
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
