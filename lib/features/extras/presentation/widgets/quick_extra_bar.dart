import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';

/// Barra de alta rápida de piezas: nombre, precio por unidad y unidades.
/// Intro en cualquier campo crea la pieza sin abrir el diálogo.
class QuickExtraBar extends StatefulWidget {
  const QuickExtraBar({super.key, required this.onCreate});

  /// Lanza si falla (quien llama avisa); la barra solo se vacía si sale bien.
  final Future<void> Function(String name, double unitPrice, int stock)
  onCreate;

  @override
  State<QuickExtraBar> createState() => _QuickExtraBarState();
}

class _QuickExtraBarState extends State<QuickExtraBar> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _nameFocus = FocusNode();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _canAdd => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _submit() async {
    if (!_canAdd) return;
    setState(() => _saving = true);
    try {
      await widget.onCreate(
        _name.text.trim(),
        parseDecimal(_price.text),
        parseInt(_stock.text),
      );
      if (!mounted) return;
      _name.clear();
      _price.clear();
      _stock.clear();
      _nameFocus.requestFocus();
    } on Object {
      // Quien llama ya avisó: se conservan los datos escritos.
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
                hintText: AppStrings.quickExtraName,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _price,
              keyboardType: decimalKeyboard,
              inputFormatters: decimalInputFormatters,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                isDense: true,
                hintText: AppStrings.quickExtraPrice,
                suffixText: '€',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: digitsOnlyFormatters,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                isDense: true,
                hintText: AppStrings.quickExtraStock,
                suffixText: 'uds',
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
