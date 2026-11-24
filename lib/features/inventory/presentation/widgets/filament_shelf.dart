import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
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
    this.spinning = const {},
    this.spinToken = 0,
  });

  final List<MaterialGroup> groups;
  final ValueChanged<PrintMaterial> onEdit;
  final ValueChanged<PrintMaterial> onDelete;

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
  });

  final MaterialGroup group;
  final Set<int> spinning;
  final int spinToken;
  final ValueChanged<PrintMaterial> onEdit;
  final ValueChanged<PrintMaterial> onDelete;

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

enum _SlotAction { edit, delete }

class _Slot extends StatelessWidget {
  const _Slot({
    required this.material,
    required this.spinToken,
    required this.onEdit,
    required this.onDelete,
  });

  static const double width = 104;

  final PrintMaterial material;
  final int spinToken;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = material.color.isEmpty ? AppStrings.noData : material.color;
    return PopupMenuButton<_SlotAction>(
      tooltip: '${material.name} · $color',
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      onSelected: (a) => switch (a) {
        _SlotAction.edit => onEdit(),
        _SlotAction.delete => onDelete(),
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _SlotAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 10),
              Text(AppStrings.edit),
            ],
          ),
        ),
        const PopupMenuItem(
          value: _SlotAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              SizedBox(width: 10),
              Text(
                AppStrings.delete,
                style: TextStyle(color: AppColors.danger),
              ),
            ],
          ),
        ),
      ],
      child: SizedBox(
        width: width - 0,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 6),
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
              Text(
                AppStrings.pricePerKg(formatEuro(material.costPerKg)),
                style: AppTextStyles.mutedSmall,
              ),
            ],
          ),
        ),
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
