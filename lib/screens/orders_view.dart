import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  // Mock data based on your CSV file (Finanza.csv)
  final List<Map<String, dynamic>> _orders = [
    {'id': '1', 'name': 'Pennywise 40cm', 'price': 50.00, 'date': '2026-02-10', 'status': 'Completed'},
    {'id': '2', 'name': 'Terminator 40cm', 'price': 70.00, 'date': '2026-02-24', 'status': 'In Progress'},
    {'id': '3', 'name': 'Renoir Peintress', 'price': 80.00, 'date': '2026-03-06', 'status': 'Reserved'},
    {'id': '4', 'name': 'D&D Super Order', 'price': 192.00, 'date': '2026-03-28', 'status': 'Completed'},
    {'id': '5', 'name': 'Catan Boxes', 'price': 12.00, 'date': '2026-03-12', 'status': 'Shipped'},
    {'id': '6', 'name': 'Pokemon Coasters', 'price': 10.00, 'date': '2026-04-12', 'status': 'Draft'},
  ];

  // Logic to assign colors to the status badges
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
          // HEADER ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Orders Management',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Action for the New Order button
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New Order form coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          // DATA TABLE
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textMain,
                      fontSize: 16,
                    ),
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
                            // Custom Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['status']).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getStatusColor(order['status']).withOpacity(0.5)),
                              ),
                              child: Text(
                                order['status'],
                                style: TextStyle(
                                  color: _getStatusColor(order['status']), 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                                  tooltip: 'Edit Order',
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.statusCancelado),
                                  tooltip: 'Delete Order',
                                  onPressed: () {},
                                ),
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
