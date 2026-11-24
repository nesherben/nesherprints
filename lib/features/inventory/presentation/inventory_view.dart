import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/core/widgets/search_field.dart';
import 'package:nesherprints/core/widgets/summary_strip.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_card.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_dialog.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_kind_chip.dart';

/// Inventario de materiales (filamento y resina).
class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  List<PrintMaterial> _materials = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ServiceLocator.materials.getAll();
      if (!mounted) return;
      setState(() => _materials = data);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _save(PrintMaterial material) async {
    try {
      await ServiceLocator.materials.save(material);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
      return;
    }
    await _load();
  }

  Future<void> _delete(PrintMaterial material) async {
    try {
      final usedBy = await ServiceLocator.materials.usageCount(material.id!);
      if (!mounted) return;
      if (usedBy > 0) {
        AppFeedback.warning(
          context,
          AppStrings.materialInUse(material.name, usedBy),
        );
        return;
      }
      final confirmed = await showConfirmDialog(
        context,
        title: AppStrings.confirmDeletionTitle,
        message: AppStrings.confirmDeletionMessage(material.name),
        confirmText: AppStrings.delete,
        color: AppColors.danger,
        icon: Icons.delete_outline,
      );
      if (!confirmed || !mounted) return;
      await ServiceLocator.materials.delete(material.id!);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
      return;
    }
    await _load();
  }

  void _openDialog([PrintMaterial? material]) {
    showDialog<void>(
      context: context,
      builder: (_) => MaterialDialog(initialMaterial: material, onSave: _save),
    );
  }

  List<PrintMaterial> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _materials;
    return [
      for (final m in _materials)
        if (m.name.toLowerCase().contains(q) ||
            m.color.toLowerCase().contains(q) ||
            m.kind.shortLabel.toLowerCase().contains(q))
          m,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final padding = context.isCompact ? AppSpacing.lg : AppSpacing.xxl;
    final visible = _filtered;
    final totalGrams = _materials.fold<double>(0, (a, m) => a + m.stockGrams);
    final lowCount = _materials.where((m) => m.isLowStock).length;

    final addButton = ElevatedButton.icon(
      onPressed: _openDialog,
      icon: const Icon(Icons.add),
      label: const Text(AppStrings.addMaterial),
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: AppStrings.inventoryTitle,
              subtitle: AppStrings.inventorySubtitle,
              action: addButton,
            ),
          ),
          if (_materials.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: AppStrings.inventoryEmptyTitle,
                message: AppStrings.inventoryEmpty,
                action: addButton,
              ),
            )
          else ...[
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
              child: SummaryStrip(
                items: [
                  SummaryItem(
                    label: AppStrings.inventorySummaryMaterials,
                    value: '${_materials.length}',
                    icon: Icons.inventory_2_outlined,
                  ),
                  SummaryItem(
                    label: AppStrings.inventorySummaryStock,
                    value: AppStrings.kilos(totalGrams),
                    icon: Icons.scale_outlined,
                    color: AppColors.info,
                  ),
                  SummaryItem(
                    label: AppStrings.inventorySummaryLow,
                    value: '$lowCount',
                    icon: Icons.warning_amber_rounded,
                    color: lowCount > 0 ? AppColors.warning : AppColors.success,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SearchField(
                  hint: AppStrings.inventorySearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off,
                  title: AppStrings.listNoResultsTitle,
                  message: AppStrings.listNoResultsMessage,
                ),
              )
            else
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 420,
                  mainAxisExtent: MaterialCard.height,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: visible.length,
                  (_, index) {
                    final material = visible[index];
                    return MaterialCard(
                      material: material,
                      onEdit: () => _openDialog(material),
                      onDelete: () => _delete(material),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
