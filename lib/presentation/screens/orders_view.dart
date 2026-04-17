import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/order_dialog.dart';
import '../../data/repositories/order_repository.dart'; // <--- AÑADE ESTO

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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'Todos';
  int? _sortColumnIndex;
  bool _isAscending = false;
  List<Map<String, dynamic>> _displayOrders = [];

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
    _applyFiltersAndSort();
  }

  @override
  void didUpdateWidget(covariant OrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orders != oldWidget.orders) {
      _applyFiltersAndSort();
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _statusFilter != 'Todos' ||
      _sortColumnIndex != null;

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
    var filtered = widget.orders.where((o) {
      final matchesSearch = o['name'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesStatus =
          _statusFilter == 'Todos' || o['status'] == _statusFilter;
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

    setState(() {
      _displayOrders = filtered;
    });
  }

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
                          dataRowMaxHeight:
                              70, // Hacemos la fila un poco más alta para que quepa la información
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
                              label: const Text('Finanzas'),
                              numeric: true,
                              onSort: _onSort,
                            ),
                            const DataColumn(
                              label: Text('Detalles'),
                            ), // Columna nueva
                            const DataColumn(label: Text('Acciones')),
                          ],
                          rows: _displayOrders.map((o) {
                            // Lógica de dineros
                            double price = (o['price'] as num).toDouble();
                            double paid = ((o['paid_amount'] ?? 0) as num)
                                .toDouble();
                            double pending = price - paid;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '#${o['id']}\n${o['date']}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
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
                                DataCell(_buildInteractiveStatusBadge(o)),

                                // CELDA DE FINANZAS ENRIQUECIDA
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total: €${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Pagado: €${paid.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: AppColors.statusCompletado,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (pending > 0)
                                        Text(
                                          'Falta: €${pending.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: AppColors.alertBajoStock,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // CELDA DE DETALLES TÉCNICOS
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (o['is_painted'] == 1)
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.brush,
                                              size: 12,
                                              color: AppColors.statusReservado,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Pintado",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      if ((o['plates'] as num) > 1)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.layers,
                                              size: 12,
                                              color: AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${o['plates']} Placas",
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (o['is_painted'] == 0 &&
                                          (o['plates'] as num) <= 1)
                                        const Text(
                                          "Estándar",
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
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

  Widget _buildInteractiveStatusBadge(Map<String, dynamic> order) {
    String status = order['status'];
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

    return PopupMenuButton<String>(
      initialValue: status,
      tooltip: 'Cambiar estado rápidamente',
      onSelected: (String newStatus) async {
        if (newStatus == status) return;

        if (newStatus == 'Completed') {
          // Desbloqueamos el pedido principal haciendo una copia por si la función intenta modificarlo
          widget.onComplete(Map<String, dynamic>.from(order));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pedido completado y stock actualizado'),
              ),
            );
          }
        } else {
          // 1. Buscamos los materiales blindados de SQLite
          final rawItems = await OrderRepository().getOrderItems(order['id']);

          // 2. MAGIA AQUÍ: Hacemos una copia "desbloqueada" y editable de cada material
          final modifiableItems = rawItems
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          // 3. Preparamos el pedido completo (también desbloqueado)
          final updatedOrder = Map<String, dynamic>.from(order);
          updatedOrder['status'] = newStatus;
          updatedOrder['items'] =
              modifiableItems; // Le pasamos la lista editable

          // 4. Actualizamos sin miedo a que colapse
          widget.onUpdate(order, updatedOrder);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
              'Draft',
              'Reserved',
              'In Progress',
              'Completed',
              'Shipped',
              'Canceled',
            ]
            .map(
              (String choice) =>
                  PopupMenuItem<String>(value: choice, child: Text(choice)),
            )
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }
}
