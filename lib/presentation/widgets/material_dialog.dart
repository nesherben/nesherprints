import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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
        widget.initialMaterial == null ? 'Añadir Material' : 'Editar Material',
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
                  labelText: 'Tipo de Material',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'filament',
                    child: Text('Filamento (Bobina)'),
                  ),
                  DropdownMenuItem(
                    value: 'resin',
                    child: Text('Resina (Tanque/Bote)'),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre/Marca',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
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
                        labelText: 'Coste por Kg (€)',
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
                        labelText: 'Stock (gramos/ml)',
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
          child: const Text('Cancelar'),
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
              'cost_per_kg': double.tryParse(_costController.text) ?? 0.0,
              'stock_g': double.tryParse(_stockController.text) ?? 0.0,
            });
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
