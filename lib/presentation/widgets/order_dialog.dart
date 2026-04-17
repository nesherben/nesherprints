import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NewOrderDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialOrder;

  const NewOrderDialog({super.key, required this.onSave, this.initialOrder});

  @override
  State<NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<NewOrderDialog> {
  late String _selectedStatus;
  late bool _isPainted;
  double _suggestedPrice = 0.0; // Referencia interna

  final _nameController = TextEditingController();
  final _gramsController = TextEditingController();
  final _platesController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final order = widget.initialOrder;
    _nameController.text = order?['name'] ?? '';
    _gramsController.text = (order?['grams'] ?? '').toString();
    _platesController.text = (order?['plates'] ?? '1').toString();
    _selectedStatus = order?['status'] ?? 'Draft';
    _isPainted = order?['is_painted'] == 1 || order?['is_painted'] == true;

    // Precio inicial
    double price = (order?['price'] as num?)?.toDouble() ?? 0.0;
    _priceController.text = price.toStringAsFixed(2);

    // Calculamos el sugerido inicial
    _calculateEstimate(updateManualPrice: false);
  }

  // Calculamos el sugerido basándonos en los costes
  void _calculateEstimate({bool updateManualPrice = true}) {
    double grams = double.tryParse(_gramsController.text) ?? 0;
    double plates = double.tryParse(_platesController.text) ?? 1;
    double costMaterial = (grams * 18.0) / 1000;
    double costPlates = (plates > 1) ? (plates - 1) * 2.50 : 0;
    double costPaint = _isPainted ? 30.0 : 0.0;

    setState(() {
      _suggestedPrice = (costMaterial + costPlates) * 1.45 + costPaint;
      // Solo actualizamos el cuadro de texto automáticamente si es un pedido nuevo
      if (updateManualPrice && widget.initialOrder == null) {
        _priceController.text = _suggestedPrice.toStringAsFixed(2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lógica de alerta: ¿El precio manual es menor que el sugerido?
    double manualPrice = double.tryParse(_priceController.text) ?? 0.0;
    bool isUnderpriced =
        manualPrice < (_suggestedPrice - 0.01); // Margen de error de redondeo

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.initialOrder == null ? 'Create Order' : 'Edit Order'),
      content: SizedBox(
        width: 500,
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
                        labelText: 'Grams',
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
                        labelText: 'Plates',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _calculateEstimate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items:
                    [
                          'Draft',
                          'Reserved',
                          'In Progress',
                          'Completed',
                          'Shipped',
                          'Canceled',
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedStatus = v!),
              ),
              CheckboxListTile(
                title: const Text("Includes Painting?"),
                value: _isPainted,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _isPainted = v!;
                  _calculateEstimate();
                }),
              ),
              const Divider(height: 32),

              // --- SECCIÓN DE PRECIOS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Suggested Price:",
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  Text(
                    "€${_suggestedPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Final Agreed Price (€)",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                onChanged: (v) =>
                    setState(() {}), // Refrescar para la alerta en tiempo real
                style: TextStyle(
                  color: isUnderpriced
                      ? AppColors.alertBajoStock
                      : AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.euro,
                    color: isUnderpriced
                        ? AppColors.alertBajoStock
                        : AppColors.primary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isUnderpriced
                          ? AppColors.alertBajoStock
                          : AppColors.secondary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isUnderpriced
                          ? AppColors.alertBajoStock
                          : AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              // --- AVISO DE PÉRDIDA DE MARGEN ---
              if (isUnderpriced && manualPrice > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.alertBajoStock,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Caution: Agreed price is lower than suggested. You are reducing your 45% profit margin.",
                          style: TextStyle(
                            color: AppColors.alertBajoStock,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
          style: ElevatedButton.styleFrom(
            backgroundColor: isUnderpriced
                ? AppColors.alertBajoStock
                : AppColors.primary,
            foregroundColor: AppColors.background,
          ),
          onPressed: () {
            widget.onSave({
              'name': _nameController.text,
              'price': double.tryParse(_priceController.text) ?? 0.0,
              'date':
                  widget.initialOrder?['date'] ??
                  DateTime.now().toString().split(' ')[0],
              'status': _selectedStatus,
              'grams': double.tryParse(_gramsController.text) ?? 0.0,
              'plates': int.tryParse(_platesController.text) ?? 1,
              'is_painted': _isPainted
                  ? 1
                  : 0, // <--- Importante: 1 o 0 para SQLite
              'material_id':
                  null, // <--- Temporalmente null hasta que hagamos el Inventario
            });
            Navigator.pop(context);
          },
          child: const Text(
            'Save Order',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
