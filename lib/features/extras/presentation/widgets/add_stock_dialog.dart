import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Suma unidades compradas a una pieza mostrando el nuevo precio medio.
class AddStockDialog extends StatefulWidget {
  const AddStockDialog({
    super.key,
    required this.extra,
    required this.onConfirm,
  });

  final Extra extra;
  final void Function(int addedUnits, double addedTotalPrice) onConfirm;

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _unitsController = TextEditingController();
  final _totalPriceController = TextEditingController();

  int get _addedUnits => parseInt(_unitsController.text);
  double get _addedTotal => parseDecimal(_totalPriceController.text);

  double get _newUnitPrice => ExtraPricing.weightedUnitPrice(
    currentStock: widget.extra.stock,
    currentUnitPrice: widget.extra.unitPrice,
    addedUnits: _addedUnits,
    addedTotal: _addedTotal,
  );

  @override
  void dispose() {
    _unitsController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canApply = _addedUnits > 0 && _addedTotal >= 0;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(AppStrings.addUnitsTo(widget.extra.name)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.currentStock(
                widget.extra.stock,
                formatEuro(widget.extra.unitPrice),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitsController,
              decoration: const InputDecoration(labelText: AppStrings.addUnits),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalPriceController,
              decoration: const InputDecoration(
                labelText: AppStrings.totalPriceOfUnits,
              ),
              keyboardType: decimalKeyboard,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.newUnitPriceEstimate(
                formatEuro(_newUnitPrice, decimals: 4),
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
          onPressed: canApply
              ? () {
                  widget.onConfirm(_addedUnits, _addedTotal);
                  Navigator.pop(context);
                }
              : null,
          style: AppButtonStyles.primary,
          child: const Text(AppStrings.apply),
        ),
      ],
    );
  }
}
