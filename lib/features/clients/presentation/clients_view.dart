import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/adaptive_sliver_list.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/core/widgets/scroll_to_top.dart';
import 'package:nesherprints/core/widgets/list_toolbar.dart';
import 'package:nesherprints/core/widgets/search_field.dart';
import 'package:nesherprints/core/widgets/summary_strip.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/clients/domain/client_stats.dart';
import 'package:nesherprints/features/clients/presentation/widgets/client_card.dart';
import 'package:nesherprints/features/clients/presentation/widgets/client_form_dialog.dart';
import 'package:nesherprints/features/clients/presentation/widgets/quick_client_bar.dart';

/// Filtro del listado de clientes.
enum _ClientFilter { all, withOrders, owes }

/// Agenda de clientes en rejilla de tarjetas.
class ClientsView extends StatefulWidget {
  const ClientsView({super.key, this.openId});

  /// Abre la ficha de este cliente al entrar (desde el buscador global).
  final int? openId;

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  List<Client> _clients = [];
  Map<int, ClientStats> _stats = {};
  bool _isLoading = true;
  String _query = '';
  _ClientFilter _filter = _ClientFilter.all;

  @override
  void initState() {
    super.initState();
    _load().then((_) => _openLaunched());
  }

  /// Si se llegó desde el buscador global, abre la ficha elegida.
  void _openLaunched() {
    final id = widget.openId;
    if (id == null || !mounted) return;
    final match = _clients.where((c) => c.id == id);
    if (match.isNotEmpty) _openDialog(match.first);
  }

  Future<void> _load() async {
    try {
      final clients = await ServiceLocator.clients.getAll();
      final orders = await ServiceLocator.orders.getAllWithDetails();
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _stats = ClientStats.fromOrders(orders);
      });
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _save(Client client) async {
    try {
      await ServiceLocator.clients.save(client);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
      return;
    }
    await _load();
  }

  Future<void> _delete(Client client) async {
    final orders = _stats[client.id]?.orderCount ?? 0;
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.confirmDeletionTitle,
      message: AppStrings.deleteClientMessage(client.name, orders),
      confirmText: AppStrings.delete,
      color: AppColors.danger,
      icon: Icons.delete_outline,
    );
    if (!ok || !mounted) return;
    try {
      await ServiceLocator.clients.delete(client.id!);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
      return;
    }
    await _load();
  }

  void _openDialog([Client? client]) {
    showDialog<void>(
      context: context,
      builder: (_) => ClientFormDialog(initialClient: client, onSave: _save),
    );
  }

  bool _matchesFilter(Client c, _ClientFilter f) {
    final stats = _stats[c.id] ?? const ClientStats();
    return switch (f) {
      _ClientFilter.all => true,
      _ClientFilter.withOrders => stats.orderCount > 0,
      _ClientFilter.owes => stats.owes,
    };
  }

  Widget _buildFilters() => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final f in _ClientFilter.values)
        ChoiceChip(
          label: Text(
            '${switch (f) {
              _ClientFilter.all => AppStrings.filterAll,
              _ClientFilter.withOrders => AppStrings.filterWithOrders,
              _ClientFilter.owes => AppStrings.filterOwes,
            }} (${_clients.where((c) => _matchesFilter(c, f)).length})',
          ),
          selected: _filter == f,
          onSelected: (_) => setState(() => _filter = f),
        ),
    ],
  );

  List<Client> get _filtered {
    final q = _query.trim().toLowerCase();
    return [
      for (final c in _clients)
        if (_matchesFilter(c, _filter) &&
            (q.isEmpty ||
                c.name.toLowerCase().contains(q) ||
                c.phone.toLowerCase().contains(q) ||
                c.email.toLowerCase().contains(q)))
          c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final padding = context.isCompact ? AppSpacing.lg : AppSpacing.xxl;
    final visible = _filtered;
    final billed = _stats.values.fold(0.0, (a, st) => a + st.billed);
    final owed = _stats.values.fold(0.0, (a, st) => a + st.pending);

    final addButton = ElevatedButton.icon(
      onPressed: _openDialog,
      icon: const Icon(Icons.person_add),
      label: const Text(AppStrings.newClient),
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: ScrollToTop(
        builder: (context, controller) => CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: AppStrings.clientsTitle,
                subtitle: AppStrings.clientsSubtitle,
                action: addButton,
              ),
            ),
            // Alta rápida (solo en pantalla ancha).
            if (context.showQuickBars) ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: QuickClientBar(
                  onCreate: (client) async {
                    await _save(client);
                  },
                ),
              ),
            ],
            if (_clients.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: AppStrings.clientsEmpty,
                  message: AppStrings.clientsEmptyMessage,
                  action: addButton,
                ),
              )
            else ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              SliverToBoxAdapter(
                child: SummaryStrip(
                  items: [
                    SummaryItem(
                      label: AppStrings.clientsSummaryCount,
                      value: '${_clients.length}',
                      icon: Icons.people_outline,
                    ),
                    SummaryItem(
                      label: AppStrings.clientsSummaryBilled,
                      value: formatEuro(billed),
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.info,
                    ),
                    SummaryItem(
                      label: AppStrings.clientsSummaryOwed,
                      value: formatEuro(owed),
                      icon: Icons.schedule,
                      color: owed > 0 ? AppColors.warning : AppColors.success,
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: ListToolbar(
                  search: SearchField(
                    hint: AppStrings.clientsSearchHint,
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
                  rowHeight: ClientCard.height,
                  columnWidth: 440,
                  itemBuilder: (_, index) {
                    final client = visible[index];
                    return ClientCard(
                      client: client,
                      stats: _stats[client.id] ?? const ClientStats(),
                      onEdit: () => _openDialog(client),
                      onDelete: () => _delete(client),
                      onSaveField: context.isCompact ? null : _save,
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
