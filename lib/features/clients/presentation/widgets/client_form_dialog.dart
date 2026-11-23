import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/clients/domain/client.dart';

/// Alta/edición de cliente. Todos los campos son opcionales; si están todos
/// vacíos se cierra sin guardar (ver `Client.fromForm`).
class ClientFormDialog extends StatefulWidget {
  const ClientFormDialog({super.key, required this.onSave, this.initialClient});

  final ValueChanged<Client> onSave;
  final Client? initialClient;

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final c = widget.initialClient;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    final client = Client.fromForm(
      id: widget.initialClient?.id,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      notes: widget.initialClient?.notes ?? '',
    );
    if (client != null) widget.onSave(client);
    Navigator.pop(context);
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
  ) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialClient == null
            ? AppStrings.newClient
            : AppStrings.editClient,
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppStrings.optionalFields,
              style: AppTextStyles.mutedSmall,
            ),
            const SizedBox(height: 16),
            _field(_nameController, AppStrings.clientNameLabel, Icons.person),
            const SizedBox(height: 16),
            _field(_phoneController, AppStrings.clientPhoneLabel, Icons.phone),
            const SizedBox(height: 16),
            _field(
              _emailController,
              AppStrings.clientContactLabel,
              Icons.alternate_email,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
    );
  }
}
