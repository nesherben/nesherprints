import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/core/widgets/list_toolbar.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/core/widgets/scroll_to_top.dart';
import 'package:nesherprints/core/widgets/search_field.dart';
import 'package:nesherprints/core/widgets/section_header.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';
import 'package:nesherprints/features/inventory/domain/material_group.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/add_resin_dialog.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/bulk_filament_dialog.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/color_library_dialog.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/filament_shelf.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_dialog.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/resin_card.dart';

/// Inventario: el tanque de resina (con su nivel y precio medio) y la lista de
/// colores de filamento con su precio, agrupados por nombre.
class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  List<PrintMaterial> _materials = [];
  ColorLibrary _library = ColorLibrary.defaults();
  bool _isLoading = true;
  String _query = '';

  /// Filamentos recién añadidos o cambiados: su bobina gira una vez.
  Set<int> _spinning = {};
  int _spinCounter = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Una sola resina: si hubiera varias se funden en un único tanque.
      await ServiceLocator.materials.mergeResins();
      final data = await ServiceLocator.materials.getAll();
      final library = await ServiceLocator.colors.load();
      if (!mounted) return;
      setState(() {
        _materials = data;
        _library = library;
      });
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// Guarda uno o varios materiales y hace girar las bobinas de filamento.
  Future<void> _saveAll(List<PrintMaterial> materials) async {
    final ids = <int>{};
    try {
      for (final m in materials) {
        final id = await ServiceLocator.materials.save(m);
        if (m.kind == MaterialKind.filament) {
          ids.add(id);
          // La biblioteca aprende los colores que se van dando de alta.
          final rgb = m.colorRgb;
          if (rgb != null && m.color.trim().isNotEmpty) {
            await ServiceLocator.colors.addIfMissing(m.color, rgb);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
      await _load();
      return;
    }
    if (!mounted) return;
    _spinCounter++;
    _spinning = ids;
    await _load();
    if (!mounted) return;
    if (materials.length > 1) {
      AppFeedback.success(context, AppStrings.bulkAdded(materials.length));
    }
  }

  Future<void> _addResin(
    PrintMaterial material,
    double grams,
    double price,
  ) async {
    try {
      // Primera vez: el tanque aún no existe en la base de datos.
      final id = material.id ?? await ServiceLocator.materials.save(material);
      await ServiceLocator.materials.addResin(
        id,
        grams: grams,
        pricePerKg: price,
      );
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
      builder: (_) => MaterialDialog(
        initialMaterial: material,
        library: _library,
        onSave: (m) => _saveAll([m]),
      ),
    );
  }

  void _openBulk() {
    showDialog<void>(
      context: context,
      builder: (_) => BulkFilamentDialog(library: _library, onSave: _saveAll),
    );
  }

  Future<void> _openColors() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ColorLibraryDialog(initial: _library),
    );
    if (!mounted) return;
    await _load();
  }

  void _openAddResin(PrintMaterial material) {
    showDialog<void>(
      context: context,
      builder: (_) => AddResinDialog(
        material: material,
        onConfirm: (grams, price) => _addResin(material, grams, price),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final padding = context.isCompact ? AppSpacing.lg : AppSpacing.xxl;
    final resins = [
      for (final m in _materials)
        if (m.kind == MaterialKind.resin) m,
    ];
    final allFilaments = [
      for (final m in _materials)
        if (m.kind == MaterialKind.filament) m,
    ];
    final q = _query.trim().toLowerCase();
    final filaments = [
      for (final m in allFilaments)
        if (q.isEmpty ||
            m.name.toLowerCase().contains(q) ||
            m.color.toLowerCase().contains(q))
          m,
    ];
    final groups = MaterialGroup.group(filaments);
    // Un único tanque; si aún no hay resina se muestra vacío.
    final tank =
        resins.firstOrNull ??
        const PrintMaterial(
          kind: MaterialKind.resin,
          name: AppStrings.defaultResinName,
          color: '',
          costPerKg: 0,
          stockGrams: 0,
        );

    final addButton = ElevatedButton.icon(
      onPressed: _openDialog,
      icon: const Icon(Icons.add),
      label: const Text(AppStrings.addMaterial),
    );
    // En móvil los secundarios son solo icono para que quepan en una fila.
    final compact = context.isCompact;
    final Widget bulkButton = compact
        ? IconButton.outlined(
            onPressed: _openBulk,
            tooltip: AppStrings.addSeveral,
            icon: const Icon(Icons.playlist_add),
          )
        : OutlinedButton.icon(
            onPressed: _openBulk,
            icon: const Icon(Icons.playlist_add),
            label: const Text(AppStrings.addSeveral),
          );

    final Widget colorsButton = compact
        ? IconButton.outlined(
            onPressed: _openColors,
            tooltip: AppStrings.colorsButton,
            icon: const Icon(Icons.palette_outlined),
          )
        : OutlinedButton.icon(
            onPressed: _openColors,
            icon: const Icon(Icons.palette_outlined),
            label: const Text(AppStrings.colorsButton),
          );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: ScrollToTop(
        builder: (context, controller) => CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: AppStrings.inventoryTitle,
                subtitle: AppStrings.inventorySubtitle,
                action: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: compact
                      ? [addButton, bulkButton, colorsButton]
                      : [colorsButton, bulkButton, addButton],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: AppStrings.resinSection,
                icon: Icons.water_drop_outlined,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: ResinCard(
                material: tank,
                onAdd: () => _openAddResin(tank),
                onEdit: tank.id == null ? null : () => _openDialog(tank),
                onDelete: tank.id == null ? null : () => _delete(tank),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: AppStrings.filamentSection,
                icon: Icons.donut_large,
                meta: allFilaments.isEmpty
                    ? null
                    : AppStrings.filamentColorsMeta(allFilaments.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            if (allFilaments.isEmpty)
              SliverToBoxAdapter(
                child: EmptyShelf(
                  actions: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: [bulkButton, addButton],
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: ListToolbar(
                  search: SearchField(
                    hint: AppStrings.inventorySearchHint,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  filters: const SizedBox.shrink(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              if (filaments.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: AppStrings.listNoResultsTitle,
                    message: AppStrings.listNoResultsMessage,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: FilamentShelf(
                    groups: groups,
                    spinning: _spinning,
                    spinToken: _spinCounter,
                    onEdit: _openDialog,
                    onDelete: _delete,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
