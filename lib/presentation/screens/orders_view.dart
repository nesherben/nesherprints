import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/order_dialog.dart';

class OrdersView extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onUpdate;
  final Function(Map<String, dynamic>) onComplete;

  const OrdersView({
    super.key,
    required this.orders,
    required this.onDelete,
    required this.onUpdate,
    required this.onComplete,
  });

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  // Variables de estado para TODOS los filtros
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'Todos';
  int? _sortColumnIndex;
  bool _isAscending = false;
  List<Map<String, dynamic>> _displayOrders = [];

  // Lista de estados disponibles para el filtro
  final List<String> _statusOptions = [
    'Todos',
    'Draft',
    'Reserved',
    'In Progress',
    'Completed',
    'Shipped',
    'Canceled',
  ];

  @override
  void initState() {
    super.initState();
    _applyFiltersAndSort(); // Carga inicial
  }

  @override
  void didUpdateWidget(covariant OrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orders != oldWidget.orders) {
      _applyFiltersAndSort();
    }
  }

  // Comprueba si hay algún filtro activo para mostrar el botón de limpiar
  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _statusFilter != 'Todos' ||
      _sortColumnIndex != null;

  // --- LÓGICA UNIFICADA ---
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = 'Todos';
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
    // 1. Aplicamos Filtros de Texto y Estado
    var filtered = widget.orders.where((o) {
      final matchesSearch = o['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesStatus =
          _statusFilter == 'Todos' || o['status'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    // 2. Aplicamos Ordenamiento
    if (_sortColumnIndex == null) {
      // Por defecto: ID descendente (el último arriba)
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

    setState(() {
      _displayOrders = filtered;
    });
  }

  // --- INTERFAZ DE USUARIO ---
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

          // BARRA DE HERRAMIENTAS (Buscador, Filtro Estado, Limpiar)
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
              // Solo mostramos el botón de limpiar si hay algo que limpiar
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
                const SizedBox(
                  width: 150,
                ), // Espaciador para mantener estructura
            ],
          ),

          const SizedBox(height: 16),

          // TABLA DE DATOS
          Expanded(
            child: Card(
              child: _displayOrders.isEmpty
                  ? const Center(
                      child: Text(
                        "No se encontraron pedidos con estos filtros.",
                      ),
                    )
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _isAscending,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                          columns: [
                            DataColumn(
                              label: const Text('ID / Fecha'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Proyecto'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Estado'),
                              onSort: _onSort,
                            ),
                            DataColumn(
                              label: const Text('Precio Final'),
                              numeric: true,
                              onSort: _onSort,
                            ),
                            const DataColumn(label: Text('Acciones')),
                          ],
                          rows: _displayOrders.map((o) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '#${o['id']} - ${o['date']}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    o['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(_buildStatusBadge(o['status'])),
                                DataCell(
                                  Text(
                                    '€${(o['price'] as num).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      if (o['status'] != 'Completed' &&
                                          o['status'] != 'Shipped' &&
                                          o['status'] != 'Canceled')
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            color: AppColors.statusCompletado,
                                            size: 20,
                                          ),
                                          tooltip: 'Marcar como Completado',
                                          onPressed: () {
                                            widget.onComplete(o);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Pedido completado y stock actualizado',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.statusReservado,
                                          size: 20,
                                        ),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) => NewOrderDialog(
                                            initialOrder: o,
                                            onSave: (updated) =>
                                                widget.onUpdate(o, updated),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.statusCancelado,
                                          size: 20,
                                        ),
                                        onPressed: () => widget.onDelete(o),
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Completed':
      case 'Shipped':
        bgColor = AppColors.statusCompletado.withOpacity(0.2);
        textColor = AppColors.statusCompletado;
        break;
      case 'In Progress':
        bgColor = AppColors.primary.withOpacity(0.2);
        textColor = AppColors.primary;
        break;
      case 'Canceled':
        bgColor = AppColors.statusCancelado.withOpacity(0.2);
        textColor = AppColors.statusCancelado;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
