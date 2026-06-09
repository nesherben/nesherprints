import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/service_locator.dart';
import '../widgets/extra_dialog.dart';
import '../widgets/add_stock_dialog.dart';

class ExtrasView extends StatefulWidget {
  const ExtrasView({super.key});

  @override
  State<ExtrasView> createState() => _ExtrasViewState();
}

class _ExtrasViewState extends State<ExtrasView> {
  List<Map<String, dynamic>> _extras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final data = await ServiceLocator.extrasRepo.getAllExtras();
    setState(() {
      _extras = data;
      _isLoading = false;
    });
  }

  void _showExtraDialog([Map<String, dynamic>? initial]) {
    showDialog(
      context: context,
      builder: (context) => ExtraDialog(
        initial: initial,
        onSave: (payload) async {
          if (payload['id'] != null) {
            await ServiceLocator.extrasRepo.updateExtra(payload['id'], payload);
          } else {
            await ServiceLocator.extrasRepo.insertExtra(payload);
          }
          await _loadExtras();
        },
      ),
    );
  }

  Future<void> _deleteExtra(int id) async {
    await ServiceLocator.extrasRepo.deleteExtra(id);
    await _loadExtras();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Piezas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showExtraDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Añadir Piezas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Scrollbar(
              child: ListView.separated(
                itemCount: _extras.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ex = _extras[index];
                  final name = ex['name'] ?? '';
                  final price = (ex['price'] as num?)?.toDouble() ?? 0.0;
                  final stock = (ex['stock'] as int?) ?? 0;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        children: [
                          // Left: details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '€${price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$stock uds',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Right: actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showExtraDialog(ex),
                                icon: const Icon(Icons.edit),
                                color: AppColors.primary,
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (ctx) => AddStockDialog(
                                      extra: ex,
                                      onConfirm:
                                          (addedUnits, addedTotal) async {
                                            final id = ex['id'] as int;
                                            final currentStock = stock;
                                            final currentPrice = price;
                                            final newStock =
                                                currentStock + addedUnits;
                                            final totalValue =
                                                currentPrice * currentStock +
                                                addedTotal;
                                            final newUnitPrice = newStock > 0
                                                ? (totalValue / newStock)
                                                : currentPrice;
                                            await ServiceLocator.extrasRepo
                                                .updateExtra(id, {
                                                  'stock': newStock,
                                                  'price': newUnitPrice,
                                                });
                                            await _loadExtras();
                                          },
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_box),
                                color: AppColors.statusCompletado,
                                tooltip: 'Sumar unidades',
                              ),
                              IconButton(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                        'Confirmar eliminación',
                                      ),
                                      content: Text(
                                        '¿Eliminar "$name"? Esta acción no se puede deshacer.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true)
                                    await _deleteExtra(ex['id'] as int);
                                },
                                icon: const Icon(Icons.delete),
                                color: AppColors.statusCancelado,
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
