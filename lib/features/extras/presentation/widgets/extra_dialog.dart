import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
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
  final _formKey = GlobalKey<FormState>();
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

  String? _validateName(String? value) =>
      (value ?? '').trim().isEmpty ? AppStrings.extraNameRequired : null;

  String? _validateUnits(String? value) =>
      parseInt(value, fallback: -1) < 0 ? AppStrings.extraUnitsInvalid : null;

  String? _validatePrice(String? value) => parseDecimal(value, fallback: -1) < 0
      ? AppStrings.extraPriceInvalid
      : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final units = parseInt(_unitsController.text);
    widget.onSave(
      Extra(
        id: widget.initial?.id,
        name: _nameController.text.trim(),
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
    final isNew = widget.initial == null;
    return AppDialogFrame(
      title: isNew ? AppStrings.addExtra : AppStrings.editExtra,
      subtitle: isNew ? null : AppStrings.extraPackageHint,
      icon: Icons.category_outlined,
      width: 460,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              validator: _validateName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: AppStrings.name),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unitsController,
                    validator: _validateUnits,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: AppStrings.unitsPerPackage,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: TextFormField(
                    controller: _totalPriceController,
                    validator: _validatePrice,
                    keyboardType: decimalKeyboard,
                    inputFormatters: decimalInputFormatters,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: AppStrings.totalPricePackage,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
