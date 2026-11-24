import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
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
    IconData icon, {
    TextInputType? keyboardType,
    bool last = false,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: last ? TextInputAction.done : TextInputAction.next,
    onSubmitted: last ? (_) => _save() : null,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialClient == null;
    return AppDialogFrame(
      title: isNew ? AppStrings.newClient : AppStrings.editClient,
      subtitle: AppStrings.optionalFields,
      icon: isNew ? Icons.person_add_alt_1_outlined : Icons.person_outline,
      width: 460,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
      child: Column(
        children: [
          _field(_nameController, AppStrings.clientNameLabel, Icons.person),
          const SizedBox(height: AppSpacing.lg),
          _field(
            _phoneController,
            AppStrings.clientPhoneLabel,
            Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.lg),
          _field(
            _emailController,
            AppStrings.clientContactLabel,
            Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            last: true,
          ),
        ],
      ),
    );
  }
}
