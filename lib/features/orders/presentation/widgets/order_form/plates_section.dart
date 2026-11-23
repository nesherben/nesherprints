import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/plate_draft.dart';

/// Sección "Configuración por Placas" del formulario de pedido.
///
/// Edita los [PlateDraft] en sitio y avisa con [onChanged] para recalcular.
class PlatesSection extends StatelessWidget {
  const PlatesSection({
    super.key,
    required this.plates,
    required this.materials,
    required this.isLocked,
    required this.onChanged,
    required this.onAddPlate,
    required this.onRemovePlate,
    required this.onAddNewMaterial,
  });

  final List<PlateDraft> plates;
  final List<PrintMaterial> materials;
  final bool isLocked;
  final VoidCallback onChanged;
  final VoidCallback onAddPlate;
  final ValueChanged<PlateDraft> onRemovePlate;

  /// Abre el alta de material y lo asigna a la placa.
  final ValueChanged<PlateDraft> onAddNewMaterial;

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
              style: AppTextStyles.sectionTitle,
            ),
            if (!isLocked)
              TextButton.icon(
                onPressed: onAddPlate,
                icon: const Icon(Icons.add_box, color: AppColors.primary),
                label: const Text(
                  AppStrings.addPlate,
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (plates.isEmpty)
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
              style: AppTextStyles.muted,
            ),
          ),
        for (final plate in plates)
          _PlateCard(
            key: plate.key,
            plate: plate,
            materials: materials,
            isLocked: isLocked,
            onChanged: onChanged,
            onRemove: () => onRemovePlate(plate),
            onAddNewMaterial: () => onAddNewMaterial(plate),
          ),
      ],
    );
  }
}

class _PlateCard extends StatelessWidget {
  const _PlateCard({
    super.key,
    required this.plate,
    required this.materials,
    required this.isLocked,
    required this.onChanged,
    required this.onRemove,
    required this.onAddNewMaterial,
  });

  final PlateDraft plate;
  final List<PrintMaterial> materials;
  final bool isLocked;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onAddNewMaterial;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: plate.name,
                    decoration: const InputDecoration(
                      labelText: AppStrings.plateNameLabel,
                      isDense: true,
                    ),
                    readOnly: isLocked,
                    onChanged: (val) {
                      plate.name = val;
                      onChanged();
                    },
                  ),
                ),
                if (!isLocked)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    // La clave incluye el material para reflejar cambios
                    // hechos desde fuera (alta de material nuevo).
                    key: ValueKey('${plate.key}-${plate.materialId}'),
                    initialValue: plate.materialId,
                    decoration: const InputDecoration(
                      labelText: AppStrings.materialLabel,
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final m in materials)
                        DropdownMenuItem<int>(
                          value: m.id,
                          child: Text(
                            AppStrings.materialOption(
                              m.name,
                              m.color,
                              formatEuro(m.costPerKg),
                            ),
                          ),
                        ),
                    ],
                    onChanged: isLocked
                        ? null
                        : (val) {
                            if (val == null) return;
                            plate.materialId = val;
                            onChanged();
                          },
                  ),
                ),
                if (!isLocked)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                    ),
                    tooltip: AppStrings.newMaterialTooltip,
                    onPressed: onAddNewMaterial,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    initial: plate.grams,
                    label: AppStrings.gramsLabel,
                    suffix: 'g',
                    readOnly: isLocked,
                    onChanged: (v) {
                      plate.grams = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    initial: plate.minutes,
                    label: AppStrings.timeLabel,
                    suffix: 'min',
                    readOnly: isLocked,
                    onChanged: (v) {
                      plate.minutes = v;
                      onChanged();
                    },
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.initial,
    required this.label,
    required this.suffix,
    required this.readOnly,
    required this.onChanged,
  });

  final double initial;
  final String label;
  final String suffix;
  final bool readOnly;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial > 0 ? initial.toString() : '',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixText: suffix,
      ),
      keyboardType: decimalKeyboard,
      readOnly: readOnly,
      inputFormatters: decimalInputFormatters,
      onChanged: (val) => onChanged(parseDecimal(val)),
    );
  }
}
