import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final List<Map<String, dynamic>> _orders = [
    {'id': '1', 'name': 'Pennywise 40cm', 'price': 50.00, 'date': '2026-02-10', 'status': 'Completed'},
    {'id': '2', 'name': 'Terminator 40cm', 'price': 70.00, 'date': '2026-02-24', 'status': 'In Progress'},
    {'id': '3', 'name': 'Renoir Peintress', 'price': 80.00, 'date': '2026-03-06', 'status': 'Reserved'},
    {'id': '4', 'name': 'D&D Super Order', 'price': 192.00, 'date': '2026-03-28', 'status': 'Completed'},
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return AppColors.statusCompletado;
      case 'In Progress': return AppColors.statusEnProceso;
      case 'Reserved': return AppColors.statusReservado;
      case 'Draft': return AppColors.statusBorrador;
      case 'Shipped': return AppColors.statusEnviado;
      case 'Canceled': return AppColors.statusCancelado;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW (Ya sin el botón viejo)
          const Text(
            'Orders Management',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 16),
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Project Name')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _orders.map((order) {
                      return DataRow(
                        cells: [
                          DataCell(Text(order['date'], style: const TextStyle(color: AppColors.textMuted))),
                          DataCell(Text(order['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text('€${order['price'].toStringAsFixed(2)}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['status']).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getStatusColor(order['status']).withOpacity(0.5)),
                              ),
                              child: Text(
                                order['status'],
                                style: TextStyle(color: _getStatusColor(order['status']), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted), onPressed: () {}),
                                IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.statusCancelado), onPressed: () {}),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET DEL FORMULARIO EMERGENTE (Sigue aquí para poder llamarlo desde main)
// ============================================================================
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
    
    double totalCost = costMaterial + costPlates;
    double finalPrice = (totalCost * 1.45) + costPaint;

    setState(() {
      _suggestedPrice = finalPrice;
    });
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gramsController,
                      decoration: const InputDecoration(labelText: 'Material (g/ml)', border: OutlineInputBorder(), suffixText: 'g'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _calculateEstimate(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _platesController,
                      decoration: const InputDecoration(labelText: 'Number of Plates', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _calculateEstimate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Initial Status', border: OutlineInputBorder()),
                      items: ['Draft', 'Reserved', 'In Progress'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => _selectedStatus = newValue!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text("Includes Painting?"),
                      value: _isPainted,
                      activeColor: AppColors.primary,
                      onChanged: (newValue) {
                        setState(() {
                          _isPainted = newValue ?? false;
                          _calculateEstimate();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Suggested Price:', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    Text('€${_suggestedPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order Saved Successfully!'), backgroundColor: AppColors.statusCompletado),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
          child: const Text('Save Order'),
        ),
      ],
    );
  }
}