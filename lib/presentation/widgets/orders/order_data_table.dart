import 'package:flutter/material.dart';

import 'package:nesherprints/core/constants.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/presentation/widgets/orders/order_form_dialog.dart';
import 'package:nesherprints/presentation/widgets/orders/status_badge.dart';

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
  final Function(Map<String, dynamic>) onWaste;

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
    required this.onWaste,
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
                  Container(
                    // Le damos un poco de aire para que el fondo se vea bien
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // Se ilumina de verde si está completado O si la deuda es 0
                      color:
                          (o['status'] == OrderStatus.completed || pending <= 0)
                          ? Colors.green.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 1. TOTAL (Le añadimos la fila para poder ponerle el check de completado al lado)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total: €${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                // El Total se pone verde si está todo pagado, si no, usa tu AppColors.primary
                                color:
                                    (o['status'] == OrderStatus.completed ||
                                        pending <= 0)
                                    ? Colors.green
                                    : AppColors.primary,
                              ),
                            ),
                            // El iconito de Check solo sale si ya está finiquitado
                            if (o['status'] == OrderStatus.completed ||
                                pending <= 0) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 14,
                              ),
                            ],
                          ],
                        ),

                        // 2. PAGADO (Intacto)
                        Text(
                          'Pagado: €${paid.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.statusCompletado,
                            fontSize: 12,
                          ),
                        ),

                        // 3. FALTA (Intacto)
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
                ),
                // --- CELDA: DETALLES TÉCNICOS (TODO INCLUIDO) ---
                DataCell(
                  Builder(
                    builder: (context) {
                      // 1. Recuperamos datos
                      int platesCount =
                          int.tryParse(o['plates_count']?.toString() ?? '0') ??
                          0;
                      double wasted = (o['total_wasted_grams'] as num? ?? 0.0)
                          .toDouble();
                      double theoretical =
                          (o['total_theoretical_grams'] as num? ?? 1.0)
                              .toDouble();

                      if (theoretical == 0) theoretical = 1.0;

                      // 2. CÁLCULO DE MERMA ACUMULATIVA (Sin límite de 100%)
                      // Si wasted es 50 y theoretical es 100 -> 50% de merma
                      // Si wasted es 150 y theoretical es 100 -> 150% de merma (más material perdido que el propio peso de la pieza)
                      double wasteRate = (wasted / theoretical) * 100;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FILA A: Pintura
                          if (o['is_painted'] == 1)
                            const Row(
                              children: [
                                Icon(
                                  Icons.brush,
                                  size: 12,
                                  color: AppColors.statusReservado,
                                ),
                                SizedBox(width: 4),
                                Text("Pintado", style: TextStyle(fontSize: 11)),
                              ],
                            ),

                          // FILA B: Placas y Tasa de Merma
                          Row(
                            children: [
                              const Icon(
                                Icons.layers,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$platesCount Placa${platesCount != 1 ? 's' : ''}",
                                style: const TextStyle(fontSize: 11),
                              ),

                              // INDICADOR DE MERMA ACUMULATIVA
                              if (wasted > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    // Lógica de colores según gravedad de la pérdida
                                    color: wasteRate > 30
                                        ? Colors.red.withOpacity(0.1)
                                        : (wasteRate > 10
                                              ? Colors.orange.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "+${wasteRate.toStringAsFixed(0)}% Merma",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: wasteRate > 30
                                          ? Colors.red
                                          : (wasteRate > 10
                                                ? Colors.orange
                                                : Colors.green),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // FILA C: Nombres de las Placas
                          if (o['plates_names'] != null &&
                              o['plates_names'].toString().isNotEmpty)
                            Text(
                              o['plates_names'],
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                // --- CELDA: ACCIONES ---
                DataCell(
                  Row(
                    children: [
                      // Botón Completar
                      if (o['status'] != OrderStatus.completed &&
                          o['status'] != OrderStatus.shipped &&
                          o['status'] != OrderStatus.canceled)
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
                        onPressed: () => onWaste(
                          o,
                        ), // <--- El hijo solo grita el aviso, no hace el trabajo
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
