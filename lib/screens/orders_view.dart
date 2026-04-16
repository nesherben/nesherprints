import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrdersView extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final Function(Map<String, dynamic>) onDelete;

  const OrdersView({super.key, required this.orders, required this.onDelete});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final Set<String> _selectedStatuses = {};
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final MenuController _menuController = MenuController();

  List<Map<String, dynamic>> get _filteredOrders {
    return widget.orders.where((order) {
      final matchesSearch = order['name'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesStatus =
          _selectedStatuses.isEmpty ||
          _selectedStatuses.contains(order['status']);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.text = "";
      _searchQuery = "";
      _selectedStatuses.clear();
    });
    if (_menuController.isOpen) _menuController.close();
  }

  // --- DIÁLOGO DE CONFIRMACIÓN ---
  void _confirmDelete(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${order['name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCancelado,
            ),
            onPressed: () {
              widget.onDelete(order);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasFilters = _selectedStatuses.isNotEmpty || _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Orders Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              if (hasFilters)
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.filter_alt_off, size: 20),
                  label: const Text(
                    'Clear All Filters',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.alertBajoStock,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterMenu(),
            ],
          ),

          // RE-AÑADIDOS: LOS CHIPS DE FILTRO
          if (_selectedStatuses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _selectedStatuses
                  .map(
                    (s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => _toggleStatus(s),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      deleteIconColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 16),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    final options = [
      'Draft',
      'Reserved',
      'In Progress',
      'Completed',
      'Shipped',
      'Canceled',
    ];
    return MenuAnchor(
      controller: _menuController,
      menuChildren: options
          .map(
            (s) => CheckboxMenuButton(
              value: _selectedStatuses.contains(s),
              onChanged: (_) => _toggleStatus(s),
              closeOnActivate: false,
              child: Text(s),
            ),
          )
          .toList(),
      builder: (context, controller, child) => IconButton.filledTonal(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: Icon(
          Icons.filter_list,
          color: _selectedStatuses.isNotEmpty
              ? AppColors.primary
              : AppColors.textMuted,
        ),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final orders = _filteredOrders;
    return Card(
      child: orders.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("No orders found matching your criteria"),
              ),
            )
          : SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Project')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: orders
                      .map(
                        (o) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                o['date'] ?? '-',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                o['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '€${(o['price'] ?? 0.0).toStringAsFixed(2)}',
                              ),
                            ),
                            // RE-AÑADIDO: EL BADGE DE COLOR
                            DataCell(_buildStatusBadge(o['status'] ?? 'Draft')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.statusCancelado,
                                      size: 20,
                                    ),
                                    onPressed: () => _confirmDelete(context, o),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }

  // RE-AÑADIDO: LA FUNCIÓN DE LOS PILLS DE COLORES
  Widget _buildStatusBadge(String status) {
    Color color = AppColors.textMuted;
    if (status == 'Completed') color = AppColors.statusCompletado;
    if (status == 'In Progress') color = AppColors.statusEnProceso;
    if (status == 'Reserved') color = AppColors.statusReservado;
    if (status == 'Shipped') color = AppColors.statusEnviado;
    if (status == 'Canceled') color = AppColors.statusCancelado;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
