import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Alta de una pieza a partir de un paquete (unidades + precio total) y edición
/// de su nombre y precio unitario. Editar **no toca el stock** (para eso está
/// «Sumar unidades»).
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
    _unitsController = TextEditingController();
    _totalPriceController = TextEditingController(
      text: extra == null ? '' : extra.unitPrice.toStringAsFixed(4),
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
    final initial = widget.initial;
    final units = parseInt(_unitsController.text);
    final price = parseDecimal(_totalPriceController.text);
    widget.onSave(
      Extra(
        id: initial?.id,
        name: _nameController.text.trim(),
        unitPrice: initial != null
            ? price
            : ExtraPricing.unitPriceFromPackage(
                totalPrice: price,
                units: units,
              ),
        stock: initial?.stock ?? units,
        unit: initial?.unit ?? '',
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial == null;
    return AppDialogFrame(
      title: isNew ? AppStrings.addExtra : AppStrings.editExtra,
      subtitle: isNew ? null : AppStrings.extraEditHint,
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
            if (isNew) ...[
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _unitsController,
                validator: _validateUnits,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: AppStrings.unitsPerPackage,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _totalPriceController,
              validator: _validatePrice,
              keyboardType: decimalKeyboard,
              inputFormatters: decimalInputFormatters,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: isNew
                    ? AppStrings.totalPricePackage
                    : AppStrings.unitPriceLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
