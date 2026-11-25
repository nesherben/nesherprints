import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/adaptive_sliver_list.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/core/widgets/scroll_to_top.dart';
import 'package:nesherprints/core/widgets/list_toolbar.dart';
import 'package:nesherprints/core/widgets/search_field.dart';
import 'package:nesherprints/core/widgets/summary_strip.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/extras/presentation/widgets/add_stock_dialog.dart';
import 'package:nesherprints/features/extras/presentation/widgets/extra_row.dart';
import 'package:nesherprints/features/extras/presentation/widgets/quick_extra_bar.dart';
import 'package:nesherprints/features/extras/presentation/widgets/extra_dialog.dart';

/// Filtro de stock del listado de piezas.
enum _ExtraFilter { all, inStock, soldOut }

/// Inventario de piezas extra (llaveros, clickers…).
class ExtrasView extends StatefulWidget {
  const ExtrasView({super.key, this.openId});

  /// Abre la edición de esta pieza al entrar (desde el buscador global).
  final int? openId;

  @override
  State<ExtrasView> createState() => _ExtrasViewState();
}

class _ExtrasViewState extends State<ExtrasView> {
  List<Extra> _extras = [];
  bool _isLoading = true;
  String _query = '';
  _ExtraFilter _filter = _ExtraFilter.all;

  @override
  void initState() {
    super.initState();
    _load().then((_) => _openLaunched());
  }

  /// Si se llegó desde el buscador global, abre la pieza elegida.
  void _openLaunched() {
    final id = widget.openId;
    if (id == null || !mounted) return;
    final match = _extras.where((e) => e.id == id);
    if (match.isNotEmpty) _openDialog(match.first);
  }

  Future<void> _load() async {
    try {
      final data = await ServiceLocator.extras.getAll();
      if (!mounted) return;
      setState(() => _extras = data);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// Ejecuta una escritura y recarga; avisa si falla.
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
      return;
    }
    await _load();
  }

  void _openDialog([Extra? extra]) {
    showDialog<void>(
      context: context,
      builder: (_) => ExtraDialog(
        initial: extra,
        onSave: (saved) => _write(() => ServiceLocator.extras.save(saved)),
      ),
    );
  }

  void _addStock(Extra extra) {
    showDialog<void>(
      context: context,
      builder: (_) => AddStockDialog(
        extra: extra,
        onConfirm: (units, total) => _write(
          () => ServiceLocator.extras.addStock(
            extra.id!,
            units: units,
            totalPrice: total,
          ),
        ),
      ),
    );
  }

  /// Borra sin preguntar y ofrece «Deshacer» (un clic menos).
  Future<void> _delete(Extra extra) async {
    await _write(() => ServiceLocator.extras.delete(extra.id!));
    if (!mounted) return;
    AppFeedback.undo(
      context,
      AppStrings.deleted(extra.name),
      () => _write(() => ServiceLocator.extras.restore(extra)),
    );
  }

  static bool _matchesFilter(Extra e, _ExtraFilter f) => switch (f) {
    _ExtraFilter.all => true,
    _ExtraFilter.inStock => e.stock > 0,
    _ExtraFilter.soldOut => e.stock <= 0,
  };

  Widget _buildFilters() => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final f in _ExtraFilter.values)
        ChoiceChip(
          label: Text(
            '${switch (f) {
              _ExtraFilter.all => AppStrings.filterAll,
              _ExtraFilter.inStock => AppStrings.filterInStock,
              _ExtraFilter.soldOut => AppStrings.filterSoldOutExtras,
            }} (${_extras.where((e) => _matchesFilter(e, f)).length})',
          ),
          selected: _filter == f,
          onSelected: (_) => setState(() => _filter = f),
        ),
    ],
  );

  List<Extra> get _filtered {
    final q = _query.trim().toLowerCase();
    final matches = [
      for (final e in _extras)
        if ((q.isEmpty || e.name.toLowerCase().contains(q)) &&
            _matchesFilter(e, _filter))
          e,
    ];
    // Con stock primero y los agotados al final; cada bloque por nombre.
    matches.sort((a, b) {
      if ((a.stock > 0) != (b.stock > 0)) return a.stock > 0 ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final padding = context.isCompact ? AppSpacing.lg : AppSpacing.xxl;
    final visible = _filtered;
    final soldOut = _extras.where((e) => e.stock <= 0).length;

    final addButton = ElevatedButton.icon(
      onPressed: _openDialog,
      icon: const Icon(Icons.add),
      label: const Text(AppStrings.addPieces),
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: ScrollToTop(
        builder: (context, controller) => CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: AppStrings.extrasTitle,
                subtitle: AppStrings.extrasSubtitle,
                action: addButton,
              ),
            ),
            // Alta rápida (solo en pantalla ancha).
            if (context.showQuickBars) ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: QuickExtraBar(
                  onCreate: (name, price, stock) async {
                    await _write(
                      () => ServiceLocator.extras.save(
                        Extra(name: name, unitPrice: price, stock: stock),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_extras.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.category_outlined,
                  title: AppStrings.extrasEmptyTitle,
                  message: AppStrings.extrasEmptyMessage,
                  action: addButton,
                ),
              )
            else ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              SliverToBoxAdapter(
                child: SummaryStrip(
                  items: [
                    SummaryItem(
                      label: AppStrings.extrasSummaryCount,
                      value: '${_extras.length}',
                      icon: Icons.category_outlined,
                    ),
                    SummaryItem(
                      label: AppStrings.extrasSummaryValue,
                      value: formatEuro(ExtraPricing.stockValue(_extras)),
                      icon: Icons.euro,
                      color: AppColors.info,
                    ),
                    SummaryItem(
                      label: AppStrings.extrasSummarySoldOut,
                      value: '$soldOut',
                      icon: Icons.remove_shopping_cart_outlined,
                      color: soldOut > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: ListToolbar(
                  search: SearchField(
                    hint: AppStrings.extrasSearchHint,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  filters: _buildFilters(),
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
                AdaptiveSliverList(
                  itemCount: visible.length,
                  rowHeight: 68,
                  columnWidth: 500,
                  itemBuilder: (_, index) {
                    final extra = visible[index];
                    return ExtraRow(
                      extra: extra,
                      onEdit: () => _openDialog(extra),
                      onAddStock: () => _addStock(extra),
                      onDelete: () => _delete(extra),
                      onSetStock: (stock) => _write(
                        () => ServiceLocator.extras.setStock(extra.id!, stock),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
