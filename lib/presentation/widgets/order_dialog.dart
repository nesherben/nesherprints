import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/material_repository.dart';

// Pequeña clase de ayuda para gestionar las filas de los filamentos
class _FilamentEntry {
  int? materialId;
  final TextEditingController gramsController = TextEditingController();
}

class NewOrderDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialOrder;

  const NewOrderDialog({super.key, required this.onSave, this.initialOrder});

  @override
  State<NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<NewOrderDialog> {
  bool _isLoading = true;

  // Repositorios
  final _settingsRepo = SettingsRepository();
  final _materialRepo = MaterialRepository();

  // Constantes del sistema
  double _margenBeneficio = 45.0;
  double _costeHoraPintado = 15.0;
  double _costePlacaExtra = 2.50;

  // Inventario
  List<Map<String, dynamic>> _resins = [];
  List<Map<String, dynamic>> _filaments = [];

  // Variables del formulario
  late String _selectedStatus;
  late bool _isPainted;
  String _materialMode = 'filament'; // 'filament' o 'resin'
  double _suggestedPrice = 0.0;

  // Controladores básicos
  final _nameController = TextEditingController();
  final _platesController = TextEditingController();
  final _priceController = TextEditingController();
  final _paintHoursController = TextEditingController(
    text: '1',
  ); // Horas de pintura

  // Controladores de Material
  int? _selectedResinId;
  final _resinGramsController = TextEditingController();
  final List<_FilamentEntry> _filamentEntries = [
    _FilamentEntry(),
  ]; // Empezamos con 1 hueco

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Cargar constantes
    final settings = await _settingsRepo.getAllSettings();
    _margenBeneficio = settings['margen_beneficio'] ?? 45.0;
    _costeHoraPintado = settings['coste_hora_pintado'] ?? 15.0;
    _costePlacaExtra = settings['coste_placa_extra'] ?? 2.50;

    // 2. Cargar inventario
    final materials = await _materialRepo.getAllMaterials();
    _resins = materials.where((m) => m['type'] == 'resin').toList();
    _filaments = materials.where((m) => m['type'] == 'filament').toList();

    // 3. Inicializar valores (Si estamos editando)
    final order = widget.initialOrder;
    _nameController.text = order?['name'] ?? '';
    _platesController.text = (order?['plates'] ?? '1').toString();
    _selectedStatus = order?['status'] ?? 'Draft';
    _isPainted = order?['is_painted'] == 1;

    if (order != null) {
      _priceController.text = (order['price'] as num).toStringAsFixed(2);
      // Nota: La carga de order_items al editar la haremos en la siguiente iteración para no complicarlo hoy.
      // Por ahora, asumimos que estamos creando o editando datos básicos.
    }

    setState(() => _isLoading = false);
    _calculateEstimate(updateManualPrice: order == null);
  }

  // --- LÓGICA FINANCIERA ---
  void _calculateEstimate({bool updateManualPrice = true}) {
    double costMaterial = 0.0;

    // Calcular coste de Resina
    if (_materialMode == 'resin' && _selectedResinId != null) {
      final res = _resins.firstWhere((r) => r['id'] == _selectedResinId);
      double g = double.tryParse(_resinGramsController.text) ?? 0;
      costMaterial = (g / 1000) * (res['cost_per_kg'] as num);
    }
    // Calcular coste de Filamentos (Suma de todos)
    else if (_materialMode == 'filament') {
      for (var entry in _filamentEntries) {
        if (entry.materialId != null) {
          final fil = _filaments.firstWhere((f) => f['id'] == entry.materialId);
          double g = double.tryParse(entry.gramsController.text) ?? 0;
          costMaterial += (g / 1000) * (fil['cost_per_kg'] as num);
        }
      }
    }

    // Calcular placas extra y pintura
    double plates = double.tryParse(_platesController.text) ?? 1;
    double costPlates = (plates > 1) ? (plates - 1) * _costePlacaExtra : 0;

    double paintHours = double.tryParse(_paintHoursController.text) ?? 0;
    double costPaint = _isPainted ? (paintHours * _costeHoraPintado) : 0.0;

    // FÓRMULA MAESTRA CON VARIABLES REALES
    setState(() {
      _suggestedPrice =
          (costMaterial + costPlates) * (1 + (_margenBeneficio / 100)) +
          costPaint;
      if (updateManualPrice) {
        _priceController.text = _suggestedPrice.toStringAsFixed(2);
      }
    });
  }

  // --- REGLA DE NEGOCIO: BLOQUEO POR COMPLETADO ---
  bool get _isLocked =>
      _selectedStatus == 'Completed' || _selectedStatus == 'Shipped';

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

    double manualPrice = double.tryParse(_priceController.text) ?? 0.0;
    bool isUnderpriced = manualPrice < (_suggestedPrice - 0.01);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.initialOrder == null ? 'Nuevo Pedido' : 'Editar Pedido'),
          if (_isLocked)
            const Chip(
              label: Text('BLOQUEADO', style: TextStyle(fontSize: 10)),
              backgroundColor: AppColors.statusCompletado,
            ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DATOS BÁSICOS
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Proyecto',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLocked,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                'Draft',
                                'Reserved',
                                'In Progress',
                                'Completed',
                                'Shipped',
                                'Canceled',
                              ]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() {
                        _selectedStatus = v!;
                      }),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // 2. SELECTOR DE MATERIAL
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'filament',
                    label: Text('Filamento'),
                    icon: Icon(Icons.blur_on),
                  ),
                  ButtonSegment(
                    value: 'resin',
                    label: Text('Resina'),
                    icon: Icon(Icons.water_drop),
                  ),
                ],
                selected: {_materialMode},
                onSelectionChanged: _isLocked
                    ? null
                    : (Set<String> newSelection) {
                        setState(() {
                          _materialMode = newSelection.first;
                          _calculateEstimate();
                        });
                      },
              ),
              const SizedBox(height: 16),

              // ZONA RESINA VS ZONA FILAMENTO
              if (_materialMode == 'resin')
                _buildResinZone()
              else
                _buildFilamentZone(),

              const Divider(height: 32),

              // 3. EXTRAS (Placas y Pintura)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _platesController,
                      decoration: const InputDecoration(
                        labelText: 'Nº Placas',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isLocked,
                      onChanged: (_) => _calculateEstimate(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text("Pintado a mano"),
                      value: _isPainted,
                      enabled: !_isLocked,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() {
                        _isPainted = v!;
                        _calculateEstimate();
                      }),
                    ),
                  ),
                  if (_isPainted)
                    Expanded(
                      child: TextField(
                        controller: _paintHoursController,
                        decoration: const InputDecoration(
                          labelText: 'Horas',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLocked,
                        onChanged: (_) => _calculateEstimate(),
                      ),
                    ),
                ],
              ),

              const Divider(height: 32),

              // 4. PRECIO FINAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Precio Sugerido (Costes + $_margenBeneficio%):",
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  Text(
                    "€${_suggestedPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                enabled: !_isLocked,
                onChanged: (v) => setState(() {}),
                style: TextStyle(
                  color: isUnderpriced
                      ? AppColors.alertBajoStock
                      : AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.euro,
                    color: isUnderpriced
                        ? AppColors.alertBajoStock
                        : AppColors.primary,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isUnderpriced
                ? AppColors.alertBajoStock
                : AppColors.primary,
            foregroundColor: AppColors.background,
          ),
          onPressed: _isLocked ? null : _saveOrder,
          child: const Text('Guardar Pedido'),
        ),
      ],
    );
  }

  // ZONA DE RESINA (Solo 1 tanque)
  Widget _buildResinZone() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            initialValue: _selectedResinId,
            decoration: const InputDecoration(
              labelText: 'Selecciona Resina',
              border: OutlineInputBorder(),
            ),
            items: _resins
                .map(
                  (r) => DropdownMenuItem<int>(
                    value: r['id'],
                    child: Text("${r['name']} (${r['color']})"),
                  ),
                )
                .toList(),
            onChanged: _isLocked
                ? null
                : (v) => setState(() {
                    _selectedResinId = v;
                    _calculateEstimate();
                  }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _resinGramsController,
            decoration: const InputDecoration(
              labelText: 'Gramos (ml)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_isLocked,
            onChanged: (_) => _calculateEstimate(),
          ),
        ),
      ],
    );
  }

  // ZONA DE FILAMENTO (Hasta 4 colores)
  Widget _buildFilamentZone() {
    return Column(
      children: [
        ..._filamentEntries.asMap().entries.map((entry) {
          int index = entry.key;
          _FilamentEntry fEntry = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: fEntry.materialId,
                    decoration: InputDecoration(
                      labelText: 'Filamento ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    items: _filaments
                        .map(
                          (f) => DropdownMenuItem<int>(
                            value: f['id'],
                            child: Text("${f['name']} (${f['color']})"),
                          ),
                        )
                        .toList(),
                    onChanged: _isLocked
                        ? null
                        : (v) => setState(() {
                            fEntry.materialId = v;
                            _calculateEstimate();
                          }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: fEntry.gramsController,
                    decoration: const InputDecoration(
                      labelText: 'Gramos',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isLocked,
                    onChanged: (_) => _calculateEstimate(),
                  ),
                ),
                if (!_isLocked)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.alertBajoStock,
                    ),
                    onPressed: _filamentEntries.length == 1
                        ? null
                        : () => setState(() {
                            _filamentEntries.removeAt(index);
                            _calculateEstimate();
                          }),
                  ),
              ],
            ),
          );
        }),
        if (_filamentEntries.length < 4 && !_isLocked)
          TextButton.icon(
            onPressed: () =>
                setState(() => _filamentEntries.add(_FilamentEntry())),
            icon: const Icon(Icons.add),
            label: const Text('Añadir otro color'),
          ),
      ],
    );
  }

  // GUARDAR: Preparar la estructura mágica para main.dart
  void _saveOrder() {
    // 1. Datos del pedido
    Map<String, dynamic> orderData = {
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'date':
          widget.initialOrder?['date'] ??
          DateTime.now().toString().split(' ')[0],
      'status': _selectedStatus,
      'grams':
          0.0, // Ya no se usa directamente, se calcula por los items, pero lo mantenemos por ahora
      'plates': int.tryParse(_platesController.text) ?? 1,
      'is_painted': _isPainted ? 1 : 0,
    };

    // 2. Materiales gastados (order_items)
    List<Map<String, dynamic>> items = [];
    if (_materialMode == 'resin' && _selectedResinId != null) {
      items.add({
        'material_id': _selectedResinId,
        'grams_used': double.tryParse(_resinGramsController.text) ?? 0.0,
      });
    } else if (_materialMode == 'filament') {
      for (var f in _filamentEntries) {
        if (f.materialId != null) {
          items.add({
            'material_id': f.materialId,
            'grams_used': double.tryParse(f.gramsController.text) ?? 0.0,
          });
        }
      }
    }

    // Truco: Metemos los items dentro del mapa para pasarlo fácil al main
    orderData['items'] = items;
    widget.onSave(orderData);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
