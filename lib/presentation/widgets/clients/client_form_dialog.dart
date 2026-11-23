import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';

class ClientFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialClient;

  const ClientFormDialog({super.key, required this.onSave, this.initialClient});

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialClient != null) {
      _nameController.text = widget.initialClient!['name'] ?? '';
      _phoneController.text = widget.initialClient!['phone'] ?? '';
      _emailController.text = widget.initialClient!['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveClient() {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();

    // Si está ABSOLUTAMENTE todo vacío, cancelamos para no guardar basura
    if (name.isEmpty && phone.isEmpty && email.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Si no hay nombre, usamos el teléfono o el email como identificador visual
    String finalName = name;
    if (finalName.isEmpty) {
      finalName = phone.isNotEmpty ? phone : email;
    }

    widget.onSave({
      'id': widget.initialClient?['id'],
      'name': finalName,
      'phone': phone,
      'email': email,
      'notes': widget.initialClient?['notes'] ?? '',
    });

    Navigator.pop(context);
  }

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
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.clientNameLabel,
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: AppStrings.clientPhoneLabel,
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: AppStrings.clientContactLabel,
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _saveClient,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
