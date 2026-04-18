import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/forms/order_form_dialog.dart';
import 'status_badge.dart';
import 'waste_dialog.dart';

class OrderDataTable extends StatelessWidget {
  // Datos
  final List<Map<String, dynamic>> displayOrders;
  final Map<int, String> clientNames;
  final int? sortColumnIndex;
  final bool isAscending;

  // Callbacks
  final Function(Map<String, dynamic>, Map<String, dynamic>) onUpdate;
  final Function(Map<String, dynamic>) onComplete;
  final Function(Map<String, dynamic>) onDelete;
  final Function(int, bool) onSort;
  final Function(String, String, Color, String, VoidCallback)
  showConfirmationDialog;

  const OrderDataTable({
    super.key,
    required this.displayOrders,
    required this.clientNames,
    required this.sortColumnIndex,
    required this.isAscending,
    required this.onUpdate,
    required this.onComplete,
    required this.onDelete,
    required this.onSort,
    required this.showConfirmationDialog,
  });

  @override
  Widget build(BuildContext context) {
    if (displayOrders.isEmpty) {
      return const Center(
        child: Text("No se encontraron pedidos con estos filtros."),
      );
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          sortColumnIndex: sortColumnIndex,
          sortAscending: isAscending,
          dataRowMaxHeight: 70,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
          columns: [
            DataColumn(
              label: const Text('ID / Fecha'),
              onSort: (columnIndex, ascending) =>
                  onSort(columnIndex, ascending),
            ),
            DataColumn(
              label: const Text('Proyecto'),
              onSort: (columnIndex, ascending) =>
                  onSort(columnIndex, ascending),
            ),
            DataColumn(
              label: const Text('Estado'),
              onSort: (columnIndex, ascending) =>
                  onSort(columnIndex, ascending),
            ),
            DataColumn(
              label: const Text('Finanzas'),
              numeric: true,
              onSort: (columnIndex, ascending) =>
                  onSort(columnIndex, ascending),
            ),
            const DataColumn(label: Text('Detalles')),
            const DataColumn(label: Text('Acciones')),
          ],
          rows: displayOrders.map((o) {
            // Lógica de dineros
            double price = (o['price'] as num).toDouble();
            double paid = ((o['paid_amount'] ?? 0) as num).toDouble();
            double pending = price - paid;

            return DataRow(
              cells: [
                // --- CELDA: ID Y FECHA ---
                DataCell(
                  Text(
                    '#${o['id']}\n${o['date']}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),

                // --- CELDA: PROYECTO CON CLIENTE ---
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o['name'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (o['client_id'] != null &&
                          clientNames.containsKey(o['client_id']))
                        Text(
                          "👤 ${clientNames[o['client_id']]}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),

                // --- CELDA: ESTADO INTERACTIVO ---
                DataCell(StatusBadge(order: o, onStatusChanged: onUpdate)),

                // --- CELDA: FINANZAS ---
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

                // --- CELDA: DETALLES TÉCNICOS ---
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            Text("Pintado", style: TextStyle(fontSize: 12)),
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
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      if (o['is_painted'] == 0 && (o['plates'] as num) <= 1)
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

                // --- CELDA: ACCIONES ---
                DataCell(
                  Row(
                    children: [
                      // Botón Completar
                      if (o['status'] != 'Completed' &&
                          o['status'] != 'Shipped' &&
                          o['status'] != 'Canceled')
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.statusCompletado,
                            size: 20,
                          ),
                          tooltip: 'Marcar como Completado (Resta Stock)',
                          onPressed: () => showConfirmationDialog(
                            '¿Completar Pedido?',
                            'Al completar este pedido, se restará el material de tu inventario. ¿La impresión ha sido exitosa?',
                            AppColors.statusCompletado,
                            'Sí, completar',
                            () {
                              onComplete(Map<String, dynamic>.from(o));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pedido completado y stock actualizado',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Botón Editar
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.statusReservado,
                          size: 20,
                        ),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => OrderFormDialog(
                            initialOrder: o,
                            onSave: (updated) => onUpdate(o, updated),
                          ),
                        ),
                      ),

                      // Botón Mermas
                      IconButton(
                        icon: const Icon(
                          Icons.recycling,
                          color: Colors.orange,
                          size: 20,
                        ),
                        tooltip: 'Registrar Impresión Fallida',
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => WasteDialog(
                            order: o,
                            onWasteRegistered: () {
                              // Podría aquí triggerear una recarga si lo deseas
                            },
                          ),
                        ),
                      ),

                      // Botón Borrar
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.statusCancelado,
                          size: 20,
                        ),
                        onPressed: () => showConfirmationDialog(
                          '¿Eliminar Pedido?',
                          'Esta acción no se puede deshacer. Los datos financieros desaparecerán.',
                          AppColors.alertBajoStock,
                          'Eliminar',
                          () => onDelete(o),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
