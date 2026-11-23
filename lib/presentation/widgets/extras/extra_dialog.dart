import 'package:flutter/material.dart';

import 'package:nesherprints/core/number_utils.dart';
import 'package:nesherprints/core/strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';

class ExtraDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initial;

  const ExtraDialog({super.key, required this.onSave, this.initial});

  @override
  State<ExtraDialog> createState() => _ExtraDialogState();
}

class _ExtraDialogState extends State<ExtraDialog> {
  final _nameController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _unitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameController.text = init?['name'] ?? '';
    // If editing, compute total price = unit_price * units (best-effort)
    final unitPrice = (init?['price'] as num?)?.toDouble();
    final stock = init?['stock'] as int? ?? 0;
    _totalPriceController.text = (unitPrice != null)
        ? (unitPrice * (stock > 0 ? stock : 1)).toStringAsFixed(2)
        : '';
    _unitsController.text = stock > 0 ? stock.toString() : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalPriceController.dispose();
    _unitsController.dispose();
    super.dispose();
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
              decoration: const InputDecoration(
                labelText: AppStrings.nameLabel,
              ),
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
              keyboardType: TextInputType.number,
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
          onPressed: () {
            final units = int.tryParse(_unitsController.text.trim()) ?? 0;
            final total = parseDecimal(_totalPriceController.text);
            final unitPrice = units > 0 ? (total / units) : (total);
            widget.onSave({
              'id': widget.initial?['id'],
              'name': _nameController.text,
              'price': unitPrice,
              'stock': units,
              'unit': widget.initial?['unit'] ?? '',
            });
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
          ),
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
