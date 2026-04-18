import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/material_repository.dart';
import '../../../data/repositories/order_repository.dart';

class WasteDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onWasteRegistered;

  const WasteDialog({
    super.key,
    required this.order,
    required this.onWasteRegistered,
  });

  @override
  State<WasteDialog> createState() => _WasteDialogState();
}

class _WasteDialogState extends State<WasteDialog> {
  final TextEditingController gramsController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  List<Map<String, dynamic>> _materials = [];
  int? selectedMaterialId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    gramsController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    final materials = await MaterialRepository().getAllMaterials();
    setState(() {
      _materials = materials;
      _isLoading = false;
    });
  }

  void _registerWaste() async {
    if (selectedMaterialId != null && gramsController.text.isNotEmpty) {
      double grams = double.tryParse(gramsController.text) ?? 0.0;

      // Guardamos la pérdida en la base de datos
      await OrderRepository().addWaste(
        widget.order['id'],
        selectedMaterialId!,
        grams,
        reasonController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onWasteRegistered();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pérdida registrada. Stock actualizado.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text('Registrar Merma - ${widget.order['name']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Añade los gramos de material perdido (espaguetis, fallos de soporte...). Se restarán de tu inventario físico y afectarán a tu beneficio neto real.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Bobina / Resina Fallida',
              border: OutlineInputBorder(),
            ),
            items: _materials
                .map(
                  (m) => DropdownMenuItem<int>(
                    value: m['id'],
                    child: Text("${m['name']} (${m['color']})"),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedMaterialId = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: gramsController,
            decoration: const InputDecoration(
              labelText: 'Gramos perdidos',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Motivo (Opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.alertBajoStock,
            foregroundColor: Colors.white,
          ),
          onPressed: _registerWaste,
          child: const Text('Registrar Pérdida'),
        ),
      ],
    );
  }
}
