import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ServiceLocator.clients.getAll();
    if (!mounted) return;
    setState(() {
      _clients = data;
      _isLoading = false;
    });
  }

  void _openDialog([Client? client]) {
    showDialog(
      context: context,
      builder: (_) => ClientFormDialog(
        initialClient: client,
        onSave: (saved) async {
          await ServiceLocator.clients.save(saved);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: AppStrings.clientsTitle,
            subtitle: AppStrings.clientsSubtitle,
            action: ElevatedButton.icon(
              onPressed: _openDialog,
              icon: const Icon(Icons.person_add),
              label: const Text(AppStrings.newClient),
              style: AppButtonStyles.primary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _clients.isEmpty
                ? const Center(
                    child: Text(
                      AppStrings.clientsEmpty,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _clients.length,
                    itemBuilder: (_, index) {
                      final client = _clients[index];
                      return ClientCard(
                        client: client,
                        onEdit: () => _openDialog(client),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
