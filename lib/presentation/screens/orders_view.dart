import 'package:flutter/material.dart';

import 'package:nesherprints/core/constants.dart';
import 'package:nesherprints/core/strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/data/service_locator.dart';
import 'package:nesherprints/presentation/widgets/orders/order_data_table.dart';
import 'package:nesherprints/presentation/widgets/orders/waste_dialog.dart';

class OrdersView extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onUpdate;
  final Function(Map<String, dynamic>) onComplete;
  final VoidCallback onRefresh;

  const OrdersView({
    super.key,
    required this.orders,
    required this.onDelete,
    required this.onUpdate,
    required this.onComplete,
    required this.onRefresh,
  });

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = AppStrings.all;
  int? _sortColumnIndex;
  bool _isAscending = false;
  List<Map<String, dynamic>> _displayOrders = [];
  final Map<int, String> _clientNames = {};

  final List<String> _statusOptions = [
    AppStrings.all,
    OrderStatus.draft,
    OrderStatus.reserved,
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.shipped,
    OrderStatus.canceled,
  ];

  @override
  void initState() {
    super.initState();
    _loadClients();
    _applyFiltersAndSort();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== CARGA DE CLIENTES ====================
  Future<void> _loadClients() async {
    final clients = await ServiceLocator.clientRepo.getAllClients();
    if (mounted) {
      setState(() {
        for (var c in clients) {
          _clientNames[c['id']] = c['name'];
        }
      });
    }
  }

  // ==================== MANEJO DE MERMAS ====================
  void _onWaste(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => WasteDialog(
        orderId: order['id'],
        onSaved: () {
          // Pedimos al padre que lea la base de datos de nuevo
          widget.onRefresh();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Merma registrada y stock actualizado'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant OrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orders != oldWidget.orders) {
      _loadClients(); // Recarga la lista de clientes
      _applyFiltersAndSort();
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _statusFilter != AppStrings.all ||
      _sortColumnIndex != null;

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = AppStrings.all;
      _sortColumnIndex = null;
      _isAscending = false;
      _applyFiltersAndSort();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    var filtered = widget.orders.where((o) {
      final matchesSearch = o['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesStatus =
          _statusFilter == AppStrings.all || o['status'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    if (_sortColumnIndex == null) {
      filtered.sort((a, b) => b['id'].compareTo(a['id']));
    } else {
      filtered.sort((a, b) {
        Comparable valueA;
        Comparable valueB;
        switch (_sortColumnIndex) {
          case 0:
            valueA = a['id'];
            valueB = b['id'];
            break;
          case 1:
            valueA = a['name'].toString().toLowerCase();
            valueB = b['name'].toString().toLowerCase();
            break;
          case 2:
            valueA = a['status'];
            valueB = b['status'];
            break;
          case 3:
            valueA = (a['price'] as num);
            valueB = (b['price'] as num);
            break;
          default:
            return 0;
        }
        return _isAscending
            ? Comparable.compare(valueA, valueB)
            : Comparable.compare(valueB, valueA);
      });
    }
    setState(() => _displayOrders = filtered);
  }

  // ==================== DIÁLOGOS DE CONFIRMACIÓN ====================
  void _showConfirmationDialog(
    String title,
    String content,
    Color confirmColor,
    String confirmText,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold),
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registro de Pedidos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 24),

          // --- BARRA DE BÚSQUEDA Y FILTROS ---
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar proyecto...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFiltersAndSort();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Estado',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _statusFilter = val;
                      _applyFiltersAndSort();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              if (_hasActiveFilters)
                ElevatedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Limpiar Filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMain,
                  ),
                )
              else
                const SizedBox(width: 150),
            ],
          ),

          const SizedBox(height: 16),

          // --- TABLA DE PEDIDOS (COMPONENTE SEPARADO) ---
          Expanded(
            child: Card(
              child: OrderDataTable(
                displayOrders: _displayOrders,
                clientNames: _clientNames,
                sortColumnIndex: _sortColumnIndex,
                isAscending: _isAscending,
                onUpdate: widget.onUpdate,
                onComplete: widget.onComplete,
                onDelete: widget.onDelete,
                onSort: _onSort,
                showConfirmationDialog: _showConfirmationDialog,
                onWaste: _onWaste,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
