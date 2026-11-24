import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/core/widgets/search_field.dart';
import 'package:nesherprints/core/widgets/summary_strip.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/extras/presentation/widgets/add_stock_dialog.dart';
import 'package:nesherprints/features/extras/presentation/widgets/extra_card.dart';
import 'package:nesherprints/features/extras/presentation/widgets/extra_dialog.dart';

/// Inventario de piezas extra (llaveros, clickers…).
class ExtrasView extends StatefulWidget {
  const ExtrasView({super.key});

  @override
  State<ExtrasView> createState() => _ExtrasViewState();
}

class _ExtrasViewState extends State<ExtrasView> {
  List<Extra> _extras = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _delete(Extra extra) async {
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.confirmDeletionTitle,
      message: AppStrings.confirmDeletionMessage(extra.name),
      confirmText: AppStrings.delete,
      color: AppColors.danger,
      icon: Icons.delete_outline,
    );
    if (!ok || !mounted) return;
    await _write(() => ServiceLocator.extras.delete(extra.id!));
  }

  List<Extra> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _extras;
    return [
      for (final e in _extras)
        if (e.name.toLowerCase().contains(q)) e,
    ];
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
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: AppStrings.extrasTitle,
              subtitle: AppStrings.extrasSubtitle,
              action: addButton,
            ),
          ),
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
                    color: soldOut > 0 ? AppColors.warning : AppColors.success,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SearchField(
                  hint: AppStrings.extrasSearchHint,
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
                  maxCrossAxisExtent: 520,
                  mainAxisExtent: ExtraCard.height,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: visible.length,
                  (_, index) {
                    final extra = visible[index];
                    return ExtraCard(
                      extra: extra,
                      onEdit: () => _openDialog(extra),
                      onAddStock: () => _addStock(extra),
                      onDelete: () => _delete(extra),
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
