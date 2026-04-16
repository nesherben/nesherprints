import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrdersView extends StatefulWidget {
  // 1. Recibimos la lista de pedidos desde el main.dart
  final List<Map<String, dynamic>> orders;

  const OrdersView({super.key, required this.orders});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final Set<String> _selectedStatuses = {};
  String _searchQuery = "";

  final TextEditingController _searchController = TextEditingController();
  final MenuController _menuController = MenuController();

  // 2. Usamos 'widget.orders' para filtrar los datos reales
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
    if (_menuController.isOpen) {
      _menuController.close();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasActiveFilters =
        _selectedStatuses.isNotEmpty || _searchQuery.isNotEmpty;

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
              if (hasActiveFilters)
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
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.text = "";
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildPersistentFilterMenu(),
            ],
          ),
          if (_selectedStatuses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
          Expanded(child: _buildOrdersTable()),
        ],
      ),
    );
  }

  Widget _buildPersistentFilterMenu() {
    final List<String> options = [
      'Draft',
      'Reserved',
      'In Progress',
      'Completed',
      'Shipped',
      'Canceled',
    ];
    return MenuAnchor(
      controller: _menuController,
      builder: (context, controller, child) {
        return IconButton.filledTonal(
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
        );
      },
      menuChildren: options
          .map(
            (status) => CheckboxMenuButton(
              value: _selectedStatuses.contains(status),
              onChanged: (bool? checked) => _toggleStatus(status),
              closeOnActivate: false,
              child: Text(status),
            ),
          )
          .toList(),
    );
  }

  Widget _buildOrdersTable() {
    final orders = _filteredOrders;

    return Card(
      child: orders.isEmpty
          ? const Center(
              child: Text(
                "No orders found",
                style: TextStyle(color: AppColors.textMuted),
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
                                o['name'] ?? 'No name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '€${(o['price'] as double).toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(_buildStatusBadge(o['status'] ?? 'Draft')),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.textMuted;
    if (status == 'Completed') color = AppColors.statusCompletado;
    if (status == 'In Progress') color = AppColors.statusEnProceso;
    if (status == 'Reserved') color = AppColors.statusReservado;

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
          fontSize: 12,
        ),
      ),
    );
  }
}
