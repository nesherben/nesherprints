import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/app/global_search.dart';
import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/order.dart';

/// Buscador global (Ctrl+K): escribe y salta a un pedido, cliente, pieza o
/// material. ↑ ↓ para moverte, Intro para abrir, Esc para cerrar. Devuelve el
/// resultado elegido o `null`.
class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key, required this.orders});

  final List<OrderSummary> orders;

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final _controller = TextEditingController();
  List<Client> _clients = const [];
  List<Extra> _extras = const [];
  List<PrintMaterial> _materials = const [];
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final clients = await ServiceLocator.clients.getAll();
      final extras = await ServiceLocator.extras.getAll();
      final materials = await ServiceLocator.materials.getAll();
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _extras = extras;
        _materials = materials;
      });
    } on Object {
      // Sin esos datos se busca solo entre los pedidos.
    }
  }

  List<SearchHit> get _hits => GlobalSearch.search(
    _controller.text,
    orders: widget.orders,
    clients: _clients,
    extras: _extras,
    materials: _materials,
  );

  void _move(int delta, int count) {
    if (count == 0) return;
    setState(() => _selected = (_selected + delta).clamp(0, count - 1));
  }

  static IconData _icon(SearchKind k) => switch (k) {
    SearchKind.order => Icons.receipt_long_outlined,
    SearchKind.client => Icons.person_outline,
    SearchKind.extra => Icons.category_outlined,
    SearchKind.material => Icons.donut_large,
  };

  static String _kindLabel(SearchKind k) => switch (k) {
    SearchKind.order => AppStrings.searchKindOrder,
    SearchKind.client => AppStrings.searchKindClient,
    SearchKind.extra => AppStrings.searchKindExtra,
    SearchKind.material => AppStrings.searchKindMaterial,
  };

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    final selected = hits.isEmpty ? 0 : _selected.clamp(0, hits.length - 1);
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                _move(1, hits.length),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                _move(-1, hits.length),
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: (_) => setState(() => _selected = 0),
                  onSubmitted: (_) {
                    if (hits.isNotEmpty) Navigator.pop(context, hits[selected]);
                  },
                  decoration: const InputDecoration(
                    hintText: AppStrings.globalSearchHint,
                    prefixIcon: Icon(Icons.search, size: 22),
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: hits.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          _controller.text.trim().isEmpty
                              ? AppStrings.globalSearchEmpty
                              : AppStrings.globalSearchNoResults,
                          style: AppTextStyles.muted,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          for (final (i, h) in hits.indexed)
                            ListTile(
                              dense: true,
                              selected: i == selected,
                              selectedTileColor: AppColors.primary.withValues(
                                alpha: 0.10,
                              ),
                              leading: Icon(_icon(h.kind), size: 20),
                              title: Text(
                                h.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: h.subtitle.isEmpty
                                  ? null
                                  : Text(
                                      h.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: Text(
                                _kindLabel(h.kind),
                                style: AppTextStyles.overline,
                              ),
                              onTap: () => Navigator.pop(context, h),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
