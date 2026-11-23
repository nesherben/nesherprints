import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/number_utils.dart';
import 'package:nesherprints/core/strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';

class MaterialFormSection extends StatefulWidget {
  final List<Map<String, dynamic>> plates;
  final List<Map<String, dynamic>> availableMaterials;
  final Function(List<Map<String, dynamic>>) onPlatesChanged;
  final Function(Function(int) onSelected)
  onAddNewMaterial; // Mantenemos tu función estrella
  final bool isLocked;

  const MaterialFormSection({
    super.key,
    required this.plates,
    required this.availableMaterials,
    required this.onPlatesChanged,
    required this.onAddNewMaterial,
    this.isLocked = false,
  });

  @override
  State<MaterialFormSection> createState() => _MaterialFormSectionState();
}

class _MaterialFormSectionState extends State<MaterialFormSection> {
  void _addPlate() {
    if (widget.isLocked) return;
    setState(() {
      widget.plates.add({
        'name': 'Placa ${widget.plates.length + 1}',
        'grams': 0.0,
        'minutes': 0.0,
        'material_id': widget.availableMaterials.isNotEmpty
            ? widget.availableMaterials.first['id']
            : null,
        'status': 'Pending',
      });
    });
    widget.onPlatesChanged(widget.plates);
  }

  void _removePlate(int index) {
    if (widget.isLocked) return;
    setState(() {
      widget.plates.removeAt(index);
    });
    widget.onPlatesChanged(widget.plates);
  }

  void _updatePlate(int index, String key, dynamic value) {
    widget.plates[index][key] = value;
    widget.onPlatesChanged(widget.plates);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.platesConfigTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            if (!widget.isLocked)
              TextButton.icon(
                onPressed: _addPlate,
                icon: const Icon(Icons.add_box, color: AppColors.primary),
                label: const Text(
                  AppStrings.addPlate,
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (widget.plates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              AppStrings.noPlates,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.plates.length,
          itemBuilder: (context, index) {
            final plate = widget.plates[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: plate['name'],
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la Placa (ej. Base)',
                              isDense: true,
                            ),
                            readOnly: widget.isLocked,
                            onChanged: (val) =>
                                _updatePlate(index, 'name', val),
                          ),
                        ),
                        if (!widget.isLocked)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.statusCancelado,
                            ),
                            onPressed: () => _removePlate(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: plate['material_id'],
                            decoration: const InputDecoration(
                              labelText: 'Material',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: widget.availableMaterials.map((m) {
                              return DropdownMenuItem<int>(
                                value: m['id'],
                                child: Text(
                                  '${m['name']} (${m['color']}) - €${m['cost_per_kg']}/kg',
                                ),
                              );
                            }).toList(),
                            onChanged: widget.isLocked
                                ? null
                                : (val) {
                                    if (val != null) {
                                      _updatePlate(index, 'material_id', val);
                                    }
                                  },
                          ),
                        ),
                        if (!widget.isLocked)
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Nuevo material',
                            onPressed: () => widget.onAddNewMaterial((newId) {
                              _updatePlate(index, 'material_id', newId);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: plate['grams'] > 0
                                ? plate['grams'].toString()
                                : '',
                            decoration: const InputDecoration(
                              labelText: AppStrings.gramsLabel,
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: 'g',
                            ),
                            keyboardType: TextInputType.number,
                            readOnly: widget.isLocked,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*[\.,]?\d*'),
                              ),
                            ],
                            onChanged: (val) =>
                                _updatePlate(index, 'grams', parseDecimal(val)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: plate['minutes'] > 0
                                ? plate['minutes'].toString()
                                : '',
                            decoration: const InputDecoration(
                              labelText: AppStrings.timeLabel,
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: 'min',
                            ),
                            keyboardType: TextInputType.number,
                            readOnly: widget.isLocked,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*[\.,]?\d*'),
                              ),
                            ],
                            onChanged: (val) => _updatePlate(
                              index,
                              'minutes',
                              parseDecimal(val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
