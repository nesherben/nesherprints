import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  // Mock data for the resin tank
  double _tankLiters = 1.2; 
  double _averagePricePerLiter = 25.0; 

  // Text controllers
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();

  void _registerPurchase() {
    double addedLiters = double.tryParse(_litersController.text) ?? 0;
    double paidPrice = double.tryParse(_totalPriceController.text) ?? 0;

    if (addedLiters > 0 && paidPrice > 0) {
      setState(() {
        // Weighted average formula
        double currentTotalValue = _tankLiters * _averagePricePerLiter;
        double newTotalValue = currentTotalValue + paidPrice;
        
        _tankLiters += addedLiters;
        _averagePricePerLiter = newTotalValue / _tankLiters;
      });

      _litersController.clear();
      _totalPriceController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resin added and average price recalculated!'),
          backgroundColor: AppColors.statusCompletado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Management',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT PANEL: Current Tank Status
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.water_drop, size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        const Text('Tank Level', style: TextStyle(color: AppColors.textMuted)),
                        Text('${_tankLiters.toStringAsFixed(2)} L', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const Divider(height: 32),
                        const Text('Current Average Cost', style: TextStyle(color: AppColors.textMuted)),
                        Text('€${_averagePricePerLiter.toStringAsFixed(2)}/L', style: const TextStyle(fontSize: 24, color: AppColors.statusEnProceso)),
                        const SizedBox(height: 8),
                        Text('(€${(_averagePricePerLiter / 1000).toStringAsFixed(4)}/ml)', style: const TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // RIGHT PANEL: Add Resin Form
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add New Bottle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _litersController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (Liters)',
                                  hintText: 'e.g. 1.0',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.scale),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _totalPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Total Price Paid (€)',
                                  hintText: 'e.g. 22.50',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.euro),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _registerPurchase,
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Mix into Tank', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
