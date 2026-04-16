import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  // --- MOCK DATA: RESIN ---
  double _tankLiters = 1.2; 
  double _averagePricePerLiter = 25.0; 

  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();

  // --- MOCK DATA: FILAMENTS ---
  final List<Map<String, dynamic>> _filaments = [
    {'name': 'PLA Pro Black', 'stock': 850, 'priceKg': 18.00},
    {'name': 'PETG Red', 'stock': 150, 'priceKg': 20.00}, // Stock bajo intencionado
    {'name': 'ABS White', 'stock': 450, 'priceKg': 22.00},
    {'name': 'Silk Gold', 'stock': 900, 'priceKg': 25.00},
  ];

  void _registerPurchase() {
    double addedLiters = double.tryParse(_litersController.text) ?? 0;
    double paidPrice = double.tryParse(_totalPriceController.text) ?? 0;

    if (addedLiters > 0 && paidPrice > 0) {
      setState(() {
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 24),
            
            // ==========================================
            // SECCIÓN 1: TANQUE DE RESINA
            // ==========================================
            const Text('Resin Tank (Liquid)', style: TextStyle(fontSize: 20, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // ==========================================
            // SECCIÓN 2: FILAMENTOS (Sólidos)
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filament Spools (Solid)', style: TextStyle(fontSize: 20, color: AppColors.textMuted)),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Spool'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.textMain),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true, // Importante para que no de error dentro de un ScrollView
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 tarjetas por fila
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _filaments.length,
              itemBuilder: (context, index) {
                final filament = _filaments[index];
                final isLowStock = filament['stock'] < 200; // Lógica de alerta
                
                return Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: isLowStock ? AppColors.alertBajoStock : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(filament['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${filament['stock']}g', 
                              style: TextStyle(
                                fontSize: 28, 
                                fontWeight: FontWeight.bold,
                                color: isLowStock ? AppColors.alertBajoStock : AppColors.textMain
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isLowStock) 
                              const Icon(Icons.warning_amber_rounded, color: AppColors.alertBajoStock, size: 20),
                          ],
                        ),
                        const Spacer(),
                        Text('Cost: €${filament['priceKg']}/kg', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}