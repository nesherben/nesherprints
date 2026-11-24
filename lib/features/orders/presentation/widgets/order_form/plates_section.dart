import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/section_card.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/plate_draft.dart';

/// Sección «Placas» del formulario de pedido.
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
    required this.onDuplicatePlate,
    required this.onAddNewMaterial,
  });

  final List<PlateDraft> plates;
  final List<PrintMaterial> materials;
  final bool isLocked;
  final VoidCallback onChanged;
  final VoidCallback onAddPlate;
  final ValueChanged<PlateDraft> onRemovePlate;
  final ValueChanged<PlateDraft> onDuplicatePlate;

  /// Abre el alta de material y lo asigna a la placa.
  final ValueChanged<PlateDraft> onAddNewMaterial;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: AppStrings.platesConfigTitle,
      subtitle: AppStrings.platesSectionHint,
      icon: Icons.layers_outlined,
      trailing: isLocked
          ? null
          : TextButton.icon(
              onPressed: onAddPlate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppStrings.addPlate),
            ),
      child: plates.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                AppStrings.noPlates,
                textAlign: TextAlign.center,
                style: AppTextStyles.muted,
              ),
            )
          : Column(
              children: [
                for (final (i, plate) in plates.indexed) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _PlateCard(
                    key: plate.key,
                    number: i + 1,
                    plate: plate,
                    materials: materials,
                    isLocked: isLocked,
                    onChanged: onChanged,
                    onRemove: () => onRemovePlate(plate),
                    onDuplicate: () => onDuplicatePlate(plate),
                    onAddNewMaterial: () => onAddNewMaterial(plate),
                  ),
                ],
              ],
            ),
    );
  }
}

class _PlateCard extends StatelessWidget {
  const _PlateCard({
    super.key,
    required this.number,
    required this.plate,
    required this.materials,
    required this.isLocked,
    required this.onChanged,
    required this.onRemove,
    required this.onDuplicate,
    required this.onAddNewMaterial,
  });

  final int number;
  final PlateDraft plate;
  final List<PrintMaterial> materials;
  final bool isLocked;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;
  final VoidCallback onAddNewMaterial;

  PrintMaterial? get _material {
    for (final m in materials) {
      if (m.id == plate.materialId) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final material = _material;
    final materialCost = material == null
        ? null
        : plate.grams / 1000 * material.costPerKg;
    final stockLeft = material?.stockGrams ?? 0;
    final lowStock = material != null && plate.grams > stockLeft;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  initialValue: plate.name,
                  decoration: const InputDecoration(
                    labelText: AppStrings.plateNameLabel,
                  ),
                  readOnly: isLocked,
                  onChanged: (val) {
                    plate.name = val;
                    onChanged();
                  },
                ),
              ),
              if (!isLocked) ...[
                IconButton(
                  tooltip: AppStrings.duplicatePlate,
                  icon: const Icon(Icons.copy_outlined, size: 19),
                  onPressed: onDuplicate,
                ),
                IconButton(
                  tooltip: AppStrings.removePlate,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.danger,
                  onPressed: onRemove,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  // La clave incluye el material para reflejar cambios hechos
                  // desde fuera (alta de un material nuevo).
                  key: ValueKey('${plate.key}-${plate.materialId}'),
                  initialValue: plate.materialId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.materialLabel,
                  ),
                  items: [
                    for (final m in materials)
                      DropdownMenuItem<int>(
                        value: m.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.materialName(m.name, m.color),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${formatEuro(m.costPerKg)}/kg',
                              style: AppTextStyles.mutedSmall,
                            ),
                          ],
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
                  tooltip: AppStrings.newMaterialTooltip,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                  onPressed: onAddNewMaterial,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
              const SizedBox(width: AppSpacing.md),
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
          if (materialCost != null && plate.grams > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  lowStock ? Icons.warning_amber_rounded : Icons.info_outline,
                  size: 14,
                  color: lowStock ? AppColors.warning : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lowStock
                        ? AppStrings.notEnoughStock(stockLeft)
                        : AppStrings.plateMaterialCost(
                            formatEuro(materialCost),
                            stockLeft,
                          ),
                    style: TextStyle(
                      fontSize: 12,
                      color: lowStock ? AppColors.warning : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
      initialValue: initial > 0 ? formatInputNumber(initial) : '',
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      keyboardType: decimalKeyboard,
      readOnly: readOnly,
      inputFormatters: decimalInputFormatters,
      onChanged: (val) => onChanged(parseDecimal(val)),
    );
  }
}
