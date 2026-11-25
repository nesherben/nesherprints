import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/features/clients/domain/client.dart';

/// Resultado: `null` si se cancela; si se acepta, el cliente elegido
/// (`Optional` con `null` = quitar el cliente).
class AssignClientResult {
  const AssignClientResult(this.clientId);

  final int? clientId;
}

/// Pide a qué cliente asignar los [count] pedidos que se ven en la lista.
class AssignClientDialog extends StatefulWidget {
  const AssignClientDialog({
    super.key,
    required this.count,
    required this.clients,
  });

  final int count;
  final List<Client> clients;

  @override
  State<AssignClientDialog> createState() => _AssignClientDialogState();
}

class _AssignClientDialogState extends State<AssignClientDialog> {
  int? _clientId;
  bool _chosen = false;

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: AppStrings.assignClientTitle,
      icon: Icons.person_add_alt_1_outlined,
      width: 460,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _chosen
              ? () => Navigator.pop(context, AssignClientResult(_clientId))
              : null,
          child: Text(AppStrings.assignClientConfirm(widget.count)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.assignClientMessage(widget.count),
            style: AppTextStyles.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<int>(
            initialValue: _clientId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: AppStrings.clientOptional,
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text(AppStrings.noClient),
              ),
              for (final c in widget.clients)
                DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() {
              _clientId = v;
              _chosen = true;
            }),
          ),
        ],
      ),
    );
  }
}
