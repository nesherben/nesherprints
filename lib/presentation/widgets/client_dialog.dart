import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ClientDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>?
  initialClient; // Añadido para poder editar en el futuro

  const ClientDialog({super.key, required this.onSave, this.initialClient});

  @override
  State<ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<ClientDialog> {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialClient == null ? 'Nuevo Cliente' : 'Editar Cliente',
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Todos los campos son opcionales. Rellena solo lo que sepas.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre / Alias',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (WhatsApp)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email / Instagram',
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
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
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
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
