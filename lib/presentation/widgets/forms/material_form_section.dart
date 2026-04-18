import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'filament_entry.dart';

class MaterialFormSection extends StatelessWidget {
  // Datos
  final String materialMode; // 'filament' o 'resin'
  final int? selectedResinId;
  final List<Map<String, dynamic>> resins;
  final List<Map<String, dynamic>> filaments;
  final TextEditingController resinGramsController;
  final List<FilamentEntry> filamentEntries;

  // Estados
  final bool isLocked;

  // Callbacks
  final Function(String) onMaterialModeChanged;
  final Function(int?) onResinSelected;
  final Function(int) onFilamentSelected;
  final Function(String) onGramsChanged;
  final Function() onAddFilament;
  final Function(int) onRemoveFilament;
  final Function(String, Function(int) onSelected) onAddNewMaterial;

  const MaterialFormSection({
    super.key,
    required this.materialMode,
    required this.selectedResinId,
    required this.resins,
    required this.filaments,
    required this.resinGramsController,
    required this.filamentEntries,
    required this.isLocked,
    required this.onMaterialModeChanged,
    required this.onResinSelected,
    required this.onFilamentSelected,
    required this.onGramsChanged,
    required this.onAddFilament,
    required this.onRemoveFilament,
    required this.onAddNewMaterial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- SELECTOR DE TIPO (Filamento vs Resina) ---
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'filament',
              label: Text('Filamento'),
              icon: Icon(Icons.blur_on),
            ),
            ButtonSegment(
              value: 'resin',
              label: Text('Resina'),
              icon: Icon(Icons.water_drop),
            ),
          ],
          selected: {materialMode},
          onSelectionChanged: isLocked
              ? null
              : (Set<String> newSelection) {
                  onMaterialModeChanged(newSelection.first);
                },
        ),
        const SizedBox(height: 16),

        // --- CONTENIDO DINÁMICO ---
        if (materialMode == 'resin')
          _buildResinZone(context)
        else
          _buildFilamentZone(context),
      ],
    );
  }

  /// Zona de Resina
  Widget _buildResinZone(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedResinId,
                  decoration: const InputDecoration(
                    labelText: 'Selecciona Resina',
                    border: OutlineInputBorder(),
                  ),
                  items: resins
                      .map(
                        (r) => DropdownMenuItem<int>(
                          value: r['id'],
                          child: Text("${r['name']} (${r['color']})"),
                        ),
                      )
                      .toList(),
                  onChanged: isLocked ? null : onResinSelected,
                ),
              ),
              if (!isLocked)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  tooltip: 'Añadir nueva resina',
                  onPressed: () => onAddNewMaterial('resin', (newId) {
                    onResinSelected(newId);
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: resinGramsController,
            decoration: const InputDecoration(
              labelText: 'Gramos (ml)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !isLocked,
            onChanged: onGramsChanged,
          ),
        ),
      ],
    );
  }

  /// Zona de Filamentos (múltiples)
  Widget _buildFilamentZone(BuildContext context) {
    return Column(
      children: [
        ...filamentEntries.asMap().entries.map((entry) {
          int index = entry.key;
          FilamentEntry fEntry = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: fEntry.materialId,
                          decoration: InputDecoration(
                            labelText: 'Filamento ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          items: filaments
                              .map(
                                (f) => DropdownMenuItem<int>(
                                  value: f['id'],
                                  child: Text("${f['name']} (${f['color']})"),
                                ),
                              )
                              .toList(),
                          onChanged: isLocked
                              ? null
                              : (v) => onFilamentSelected(index),
                        ),
                      ),
                      if (!isLocked)
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Añadir nuevo filamento',
                          onPressed: () =>
                              onAddNewMaterial('filament', (newId) {
                                fEntry.materialId = newId;
                                onFilamentSelected(index);
                              }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: fEntry.gramsController,
                    decoration: const InputDecoration(
                      labelText: 'Gramos',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isLocked,
                    onChanged: (_) => onGramsChanged(''),
                  ),
                ),
                if (!isLocked)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.alertBajoStock,
                    ),
                    onPressed: filamentEntries.length == 1
                        ? null
                        : () => onRemoveFilament(index),
                  ),
              ],
            ),
          );
        }),
        if (filamentEntries.length < 4 && !isLocked)
          TextButton.icon(
            onPressed: onAddFilament,
            icon: const Icon(Icons.add),
            label: const Text('Añadir otro color'),
          ),
      ],
    );
  }
}
