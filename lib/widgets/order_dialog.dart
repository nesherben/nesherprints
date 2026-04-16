import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/order_model.dart';

class NewOrderDialog extends StatefulWidget {
  const NewOrderDialog({super.key});

  @override
  State<NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<NewOrderDialog> {
  String _selectedStatus = 'Draft';
  bool _isPainted = false;
  double _suggestedPrice = 0.0;

  final _nameController = TextEditingController();
  final _gramsController = TextEditingController();
  final _platesController = TextEditingController(text: '1');

  void _calculateEstimate() {
    double grams = double.tryParse(_gramsController.text) ?? 0;
    double plates = double.tryParse(_platesController.text) ?? 1;
    double costMaterial = (grams * 18.0) / 1000;
    double costPlates = (plates > 1) ? (plates - 1) * 2.50 : 0;
    double costPaint = _isPainted ? 30.0 : 0.0;

    setState(
      () => _suggestedPrice = (costMaterial + costPlates) * 1.45 + costPaint,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Create New Order'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gramsController,
                      decoration: const InputDecoration(
                        labelText: 'Material (g/ml)',
                        border: OutlineInputBorder(),
                        suffixText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _calculateEstimate(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _platesController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Plates',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _calculateEstimate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Initial Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Draft', 'Reserved', 'In Progress']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text("Painted?"),
                      value: _isPainted,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() {
                        _isPainted = v!;
                        _calculateEstimate();
                      }),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                'Suggested: €${_suggestedPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Save Order'),
        ),
      ],
    );
  }
}
