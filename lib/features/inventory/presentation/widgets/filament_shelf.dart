import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/inline_edit_cell.dart';
import 'package:nesherprints/features/inventory/domain/material_group.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/filament_color.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/spool_icon.dart';

/// Estantería de filamento: una estantería por marca/nombre con sus bobinas
/// apoyadas en baldas de ancho completo, cada una de su color y con su precio
/// debajo. Tocar una bobina abre su menú (editar / eliminar).
class FilamentShelf extends StatelessWidget {
  const FilamentShelf({
    super.key,
    required this.groups,
    required this.onEdit,
    required this.onDelete,
    this.onSetPrice,
    this.spinning = const {},
    this.spinToken = 0,
  });

  final List<MaterialGroup> groups;
  final ValueChanged<PrintMaterial> onEdit;
  final ValueChanged<PrintMaterial> onDelete;

  /// Cambio rápido del precio por kilo pulsándolo.
  final Future<void> Function(PrintMaterial material, double price)? onSetPrice;

  /// Bobinas que giran (recién añadidas o cambiadas).
  final Set<int> spinning;
  final int spinToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, group) in groups.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          _Shelf(
            group: group,
            spinning: spinning,
            spinToken: spinToken,
            onEdit: onEdit,
            onDelete: onDelete,
            onSetPrice: onSetPrice,
          ),
        ],
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.group,
    required this.spinning,
    required this.spinToken,
    required this.onEdit,
    required this.onDelete,
    this.onSetPrice,
  });

  final MaterialGroup group;
  final Set<int> spinning;
  final int spinToken;
  final ValueChanged<PrintMaterial> onEdit;
  final ValueChanged<PrintMaterial> onDelete;
  final Future<void> Function(PrintMaterial material, double price)? onSetPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                Text(
                  AppStrings.shelfBrandMeta(group.materials.length),
                  style: AppTextStyles.mutedSmall,
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              // Cuántas bobinas caben por balda; cada fila lleva su tabla de
              // ancho completo debajo.
              final perRow = (constraints.maxWidth / _Slot.width).floor().clamp(
                1,
                1000,
              );
              final rows = <List<PrintMaterial>>[
                for (var i = 0; i < group.materials.length; i += perRow)
                  group.materials.sublist(
                    i,
                    (i + perRow).clamp(0, group.materials.length),
                  ),
              ];
              return Column(
                children: [
                  for (final row in rows)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              for (final m in row)
                                _Slot(
                                  material: m,
                                  spinToken: spinning.contains(m.id)
                                      ? spinToken
                                      : 0,
                                  onEdit: () => onEdit(m),
                                  onDelete: () => onDelete(m),
                                  onSetPrice: onSetPrice == null
                                      ? null
                                      : (price) => onSetPrice!(m, price),
                                ),
                            ],
                          ),
                        ),
                        const _Plank(),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Tabla de la balda: ancho completo, con un filo claro arriba y sombra
/// debajo.
class _Plank extends StatelessWidget {
  const _Plank();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondary, AppColors.surfaceHigh],
        ),
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.material,
    required this.spinToken,
    required this.onEdit,
    required this.onDelete,
    this.onSetPrice,
  });

  static const double width = 104;

  final PrintMaterial material;
  final int spinToken;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function(double price)? onSetPrice;

  @override
  Widget build(BuildContext context) {
    final color = material.color.isEmpty ? AppStrings.noData : material.color;
    final priceText = Text(
      AppStrings.pricePerKg(formatEuro(material.costPerKg)),
      style: AppTextStyles.mutedSmall,
    );
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tocar la bobina abre la edición directamente.
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: onEdit,
                  child: Tooltip(
                    message: '${material.name} · $color',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpoolIcon(
                          color: filamentColorFor(material),
                          size: 64,
                          spinToken: spinToken,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            color,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // El precio se cambia pulsándolo.
                InlineMoneyCell(
                  value: material.costPerKg,
                  suffix: '€/kg',
                  enabled: onSetPrice != null,
                  tooltip: AppStrings.editPriceTip,
                  display: priceText,
                  onSubmit: (v) => onSetPrice!(v),
                ),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 12,
            child: IconButton(
              tooltip: AppStrings.delete,
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.textMuted,
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                maximumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estantería vacía: la tabla sin bobinas y un mensaje, para invitar a
/// llenarla.
class EmptyShelf extends StatelessWidget {
  const EmptyShelf({super.key, required this.actions});

  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Icon(
                  Icons.donut_large,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  AppStrings.shelfEmptyTitle,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  AppStrings.shelfEmptyMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.muted,
                ),
                const SizedBox(height: AppSpacing.lg),
                actions,
              ],
            ),
          ),
          const _Plank(),
        ],
      ),
    );
  }
}
