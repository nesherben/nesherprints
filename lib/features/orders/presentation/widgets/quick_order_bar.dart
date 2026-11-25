import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/clients/domain/client.dart';

/// Barra de alta rápida encima de la tabla: nombre, cliente y precio, e Intro
/// para crear un borrador sin abrir el formulario (las placas se añaden
/// después). [onCreate] lanza si falla; la barra solo se vacía si sale bien.
class QuickOrderBar extends StatefulWidget {
  const QuickOrderBar({
    super.key,
    required this.clients,
    required this.onCreate,
    this.focusNode,
  });

  final List<Client> clients;
  final Future<void> Function(String name, int? clientId, double price)
  onCreate;

  /// Foco del campo de nombre (para el atajo de teclado).
  final FocusNode? focusNode;

  @override
  State<QuickOrderBar> createState() => _QuickOrderBarState();
}

class _QuickOrderBarState extends State<QuickOrderBar> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  int? _clientId;
  bool _saving = false;
  late final FocusNode _nameFocus = widget.focusNode ?? FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    if (widget.focusNode == null) _nameFocus.dispose();
    super.dispose();
  }

  bool get _canAdd => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _submit() async {
    if (!_canAdd) return;
    setState(() => _saving = true);
    try {
      await widget.onCreate(
        _name.text.trim(),
        _clientId,
        parseDecimal(_price.text),
      );
      if (!mounted) return;
      _name.clear();
      _price.clear();
      _nameFocus.requestFocus();
    } on Object {
      // El que llama ya avisó del error: se conservan los datos escritos.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
            child: TextField(
              controller: _name,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                isDense: true,
                hintText: AppStrings.quickOrderName,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              key: ValueKey(widget.clients.length),
              initialValue: _clientId,
              isExpanded: true,
              isDense: true,
              hint: const Text(AppStrings.unassigned),
              decoration: const InputDecoration(isDense: true),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text(AppStrings.unassigned),
                ),
                for (final c in widget.clients)
                  DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => _clientId = v,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _price,
              keyboardType: decimalKeyboard,
              inputFormatters: decimalInputFormatters,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                isDense: true,
                hintText: AppStrings.quickOrderPrice,
                suffixText: '€',
              ),
            ),
          ),
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
