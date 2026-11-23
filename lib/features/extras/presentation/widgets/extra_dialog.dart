import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Alta/edición de una pieza a partir de un paquete (unidades + precio total).
///
/// Al editar, las unidades sustituyen al stock actual.
class ExtraDialog extends StatefulWidget {
  const ExtraDialog({super.key, required this.onSave, this.initial});

  final ValueChanged<Extra> onSave;
  final Extra? initial;

  @override
  State<ExtraDialog> createState() => _ExtraDialogState();
}

class _ExtraDialogState extends State<ExtraDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitsController;
  late final TextEditingController _totalPriceController;

  @override
  void initState() {
    super.initState();
    final extra = widget.initial;
    _nameController = TextEditingController(text: extra?.name ?? '');
    _unitsController = TextEditingController(
      text: (extra != null && extra.stock > 0) ? '${extra.stock}' : '',
    );
    _totalPriceController = TextEditingController(
      text: extra == null
          ? ''
          : ExtraPricing.packageTotal(extra).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalPriceController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  void _save() {
    final units = parseInt(_unitsController.text);
    widget.onSave(
      Extra(
        id: widget.initial?.id,
        name: _nameController.text,
        unitPrice: ExtraPricing.unitPriceFromPackage(
          totalPrice: parseDecimal(_totalPriceController.text),
          units: units,
        ),
        stock: units,
        unit: widget.initial?.unit ?? '',
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.initial == null ? AppStrings.addExtra : AppStrings.editExtra,
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: AppStrings.name),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitsController,
              decoration: const InputDecoration(
                labelText: AppStrings.unitsPerPackage,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalPriceController,
              decoration: const InputDecoration(
                labelText: AppStrings.totalPricePackage,
              ),
              keyboardType: decimalKeyboard,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          style: AppButtonStyles.primary,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
