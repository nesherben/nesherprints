import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/data/service_locator.dart';

class WasteDialog extends StatefulWidget {
  final int orderId;
  final VoidCallback onSaved;

  const WasteDialog({super.key, required this.orderId, required this.onSaved});

  @override
  State<WasteDialog> createState() => _WasteDialogState();
}

class _WasteDialogState extends State<WasteDialog> {
  bool _isLoading = true;

  List<Map<String, dynamic>> _plates = [];
  int? _selectedPlateId;
  double _wastePercentage = 100.0; // Por defecto asumimos que se perdió entera
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlates();
  }

  Future<void> _loadPlates() async {
    // Descargamos las placas específicas de este pedido
    final plates = await ServiceLocator.orderRepo.getOrderPlates(
      widget.orderId,
    );
    setState(() {
      _plates = plates;
      if (_plates.isNotEmpty) {
        _selectedPlateId = _plates.first['id'];
      }
      _isLoading = false;
    });
  }

  // Calculadora mágica en tiempo real
  double get _calculatedWastedGrams {
    if (_selectedPlateId == null) return 0.0;
    final plate = _plates.firstWhere(
      (p) => p['id'] == _selectedPlateId,
      orElse: () => {},
    );
    if (plate.isEmpty) return 0.0;

    double totalGrams = (plate['grams'] as num).toDouble();
    return totalGrams * (_wastePercentage / 100);
  }

  Future<void> _saveWaste() async {
    if (_selectedPlateId == null) return;

    final plate = _plates.firstWhere((p) => p['id'] == _selectedPlateId);
    int materialId = plate['material_id'];
    double gramsWasted = _calculatedWastedGrams;
    String reason = _reasonController.text.trim().isEmpty
        ? 'Fallo al ${_wastePercentage.toInt()}% en ${plate['name']}'
        : _reasonController.text;

    // Llamamos a tu repositorio para guardar la merma y restar stock
    await ServiceLocator.orderRepo.addWaste(
      orderId: widget.orderId,
      materialId: materialId,
      grams: gramsWasted,
      reason: reason,
    );

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Registrar Merma'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _plates.isEmpty
            ? const Text(
                'Este pedido no tiene placas configuradas.',
                style: TextStyle(color: AppColors.textMuted),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SELECTOR DE PLACA
                  const Text(
                    '¿Qué placa ha fallado?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedPlateId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _plates.map((p) {
                      return DropdownMenuItem<int>(
                        value: p['id'],
                        child: Text('${p['name']} (${p['grams']}g)'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPlateId = val),
                  ),
                  const SizedBox(height: 24),

                  // 2. SLIDER DE PORCENTAJE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '¿Cuánto se llegó a imprimir?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_wastePercentage.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _wastePercentage,
                    min: 0,
                    max: 100,
                    divisions: 20, // Saltos de 5% en 5%
                    activeColor: Colors.orange,
                    label: '${_wastePercentage.toInt()}%',
                    onChanged: (val) => setState(() => _wastePercentage = val),
                  ),

                  // 3. TEXTO DINÁMICO DEL CÁLCULO
                  Center(
                    child: Text(
                      'Se descontarán ${_calculatedWastedGrams.toStringAsFixed(1)}g del inventario',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. MOTIVO (Opcional)
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo del fallo (Opcional)',
                      hintText:
                          'Ej: Se soltó de la cama, atasco de boquilla...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        if (_plates.isNotEmpty)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: _saveWaste,
            child: const Text(AppStrings.registerWaste),
          ),
      ],
    );
  }
}
