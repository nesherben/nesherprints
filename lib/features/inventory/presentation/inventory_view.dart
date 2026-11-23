import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_dialog.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_kind_chip.dart';

/// Inventario de materiales (filamento y resina).
class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  List<PrintMaterial> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ServiceLocator.materials.getAll();
    if (!mounted) return;
    setState(() {
      _materials = data;
      _isLoading = false;
    });
  }

  Future<void> _save(PrintMaterial material) async {
    await ServiceLocator.materials.save(material);
    await _load();
  }

  /// Borra sin confirmación (comportamiento actual).
  Future<void> _delete(PrintMaterial material) async {
    await ServiceLocator.materials.delete(material.id!);
    await _load();
  }

  void _openDialog([PrintMaterial? material]) {
    showDialog(
      context: context,
      builder: (_) => MaterialDialog(initialMaterial: material, onSave: _save),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: AppStrings.inventoryTitle,
            action: ElevatedButton.icon(
              onPressed: _openDialog,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addMaterial),
              style: AppButtonStyles.primary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: _materials.isEmpty
                  ? const Center(child: Text(AppStrings.inventoryEmpty))
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildTable(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return DataTable(
      headingTextStyle: AppTextStyles.tableHeading,
      columns: const [
        DataColumn(label: Text(AppStrings.colType)),
        DataColumn(label: Text(AppStrings.name)),
        DataColumn(label: Text(AppStrings.colColor)),
        DataColumn(label: Text(AppStrings.colCostPerKg)),
        DataColumn(label: Text(AppStrings.colStockLeft)),
        DataColumn(label: Text(AppStrings.colActions)),
      ],
      rows: [
        for (final m in _materials)
          DataRow(
            cells: [
              DataCell(MaterialKindChip(kind: m.kind)),
              DataCell(Text(m.name)),
              DataCell(Text(m.color)),
              DataCell(Text(formatEuro(m.costPerKg))),
              DataCell(
                Text(
                  AppStrings.grams(m.stockGrams),
                  style: TextStyle(
                    color: m.isLowStock
                        ? AppColors.dangerBright
                        : AppColors.success,
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
                        color: AppColors.info,
                        size: 20,
                      ),
                      onPressed: () => _openDialog(m),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      onPressed: () => _delete(m),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
