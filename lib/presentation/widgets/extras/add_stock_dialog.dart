import 'package:flutter/material.dart';

import 'package:nesherprints/core/number_utils.dart';
import 'package:nesherprints/core/strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';

class AddStockDialog extends StatefulWidget {
  final Map<String, dynamic> extra;
  final Function(int addedUnits, double addedTotalPrice) onConfirm;

  const AddStockDialog({
    super.key,
    required this.extra,
    required this.onConfirm,
  });

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _unitsController = TextEditingController();
  final _totalPriceController = TextEditingController();

  double get _currentUnitPrice =>
      (widget.extra['price'] as num?)?.toDouble() ?? 0.0;
  int get _currentStock => (widget.extra['stock'] as int?) ?? 0;

  double get _addedTotal => parseDecimal(_totalPriceController.text);
  int get _addedUnits => int.tryParse(_unitsController.text.trim()) ?? 0;

  double get _newUnitPrice {
    final newStock = _currentStock + _addedUnits;
    if (newStock <= 0) return _currentUnitPrice;
    final totalValue = _currentUnitPrice * _currentStock + _addedTotal;
    return totalValue / newStock;
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('${AppStrings.addUnits} a "${widget.extra['name'] ?? ''}"'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Actualmente: $_currentStock unidades · €${_currentUnitPrice.toStringAsFixed(2)} c/u',
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
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(
              'Nuevo precio unitario estimado: €${_newUnitPrice.toStringAsFixed(4)}',
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
          onPressed: _addedUnits > 0 && _addedTotal >= 0
              ? () {
                  widget.onConfirm(_addedUnits, _addedTotal);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
          ),
          child: const Text(AppStrings.apply),
        ),
      ],
    );
  }
}
