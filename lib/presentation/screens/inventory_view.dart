import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/service_locator.dart';
import '../widgets/material_dialog.dart';
import '../../core/strings.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  List<Map<String, dynamic>> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final data = await ServiceLocator.materialRepo.getAllMaterials();
    setState(() {
      _materials = data;
      _isLoading = false;
    });
  }

  Future<void> _saveMaterial(Map<String, dynamic> material) async {
    if (material['id'] == null) {
      await ServiceLocator.materialRepo.insertMaterial(material);
    } else {
      await ServiceLocator.materialRepo.updateMaterial(material);
    }
    _loadMaterials();
  }

  Future<void> _deleteMaterial(int id) async {
    await ServiceLocator.materialRepo.deleteMaterial(id);
    _loadMaterials();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestor de Inventario',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => MaterialDialog(onSave: _saveMaterial),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Añadir Material'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _materials.isEmpty
                  ? const Center(
                      child: Text(
                        "No hay materiales en el inventario. Añade tu primera bobina o tanque de resina.",
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
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text(AppStrings.nameColumn)),
                            DataColumn(label: Text('Color')),
                            DataColumn(label: Text('Coste/Kg')),
                            DataColumn(label: Text('Stock Restante')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: _materials.map((m) {
                            bool isLowStock =
                                (m['stock_g'] as num) <
                                200; // Alerta si hay menos de 200g
                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m['type'] == 'resin'
                                          ? Colors.deepPurple.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      m['type'] == 'resin'
                                          ? 'Resina'
                                          : 'Filamento',
                                      style: TextStyle(
                                        color: m['type'] == 'resin'
                                            ? Colors.deepPurpleAccent
                                            : Colors.orangeAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(m['name'] ?? '')),
                                DataCell(Text(m['color'] ?? '')),
                                DataCell(
                                  Text(
                                    '€${(m['cost_per_kg'] as num).toStringAsFixed(2)}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${(m['stock_g'] as num).toStringAsFixed(0)} g',
                                    style: TextStyle(
                                      color: isLowStock
                                          ? AppColors.alertBajoStock
                                          : AppColors.statusCompletado,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.statusReservado,
                                          size: 20,
                                        ),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) => MaterialDialog(
                                            initialMaterial: m,
                                            onSave: _saveMaterial,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.statusCancelado,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _deleteMaterial(m['id']),
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
