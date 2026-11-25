import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/features/clients/domain/client.dart';

/// Barra de alta rápida de clientes: nombre, teléfono y email/Instagram.
/// Intro en cualquier campo crea el cliente sin abrir el diálogo.
class QuickClientBar extends StatefulWidget {
  const QuickClientBar({super.key, required this.onCreate});

  final Future<void> Function(Client client) onCreate;

  @override
  State<QuickClientBar> createState() => _QuickClientBarState();
}

class _QuickClientBarState extends State<QuickClientBar> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _nameFocus = FocusNode();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Client? get _client =>
      Client.fromForm(name: _name.text, phone: _phone.text, email: _email.text);

  bool get _canAdd => _client != null && !_saving;

  Future<void> _submit() async {
    final client = _client;
    if (client == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onCreate(client);
      if (!mounted) return;
      _name.clear();
      _phone.clear();
      _email.clear();
      _nameFocus.requestFocus();
    } on Object {
      // Quien llama ya avisó: se conservan los datos escritos.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    FocusNode? focus,
    TextInputType? type,
  }) => TextField(
    controller: controller,
    focusNode: focus,
    keyboardType: type,
    textInputAction: TextInputAction.next,
    onChanged: (_) => setState(() {}),
    onSubmitted: (_) => _submit(),
    decoration: InputDecoration(isDense: true, hintText: hint),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: _field(_name, AppStrings.quickClientName, focus: _nameFocus),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: _field(
              _phone,
              AppStrings.quickClientPhone,
              type: TextInputType.phone,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 3, child: _field(_email, AppStrings.quickClientEmail)),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: _canAdd ? _submit : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(AppStrings.quickOrderAdd),
          ),
        ],
      ),
    );
  }
}
