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
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/clients/domain/client_stats.dart';
import 'package:nesherprints/features/clients/presentation/widgets/client_card.dart';
import 'package:nesherprints/features/clients/presentation/widgets/client_form_dialog.dart';

/// Agenda de clientes en rejilla de tarjetas.
class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  List<Client> _clients = [];
  Map<int, ClientStats> _stats = {};
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
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

  List<Client> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _clients;
    return [
      for (final c in _clients)
        if (c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q))
          c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final padding = context.isCompact ? AppSpacing.lg : AppSpacing.xxl;
    final visible = _filtered;

    final addButton = ElevatedButton.icon(
      onPressed: _openDialog,
      icon: const Icon(Icons.person_add),
      label: const Text(AppStrings.newClient),
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: AppStrings.clientsTitle,
              subtitle: AppStrings.clientsSubtitle,
              action: addButton,
            ),
          ),
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: SearchField(
                  hint: AppStrings.clientsSearchHint,
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
                  maxCrossAxisExtent: 340,
                  mainAxisExtent: ClientCard.height,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: visible.length,
                  (_, index) {
                    final client = visible[index];
                    return ClientCard(
                      client: client,
                      stats: _stats[client.id] ?? const ClientStats(),
                      onEdit: () => _openDialog(client),
                      onDelete: () => _delete(client),
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
