import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/client_repository.dart'; // <--- NUEVO
import 'material_dialog.dart';
import 'client_dialog.dart'; // <--- NUEVO

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
  final _orderRepo = OrderRepository();
  final _clientRepo = ClientRepository(); // <--- NUEVO

  // Constantes del sistema
  double _margenBeneficio = 45.0;
  double _costeHoraPintado = 15.0;
  double _costePlacaExtra = 2.50;

  // Listas de la Base de Datos
  List<Map<String, dynamic>> _resins = [];
  List<Map<String, dynamic>> _filaments = [];
  List<Map<String, dynamic>> _clients = []; // <--- NUEVO

  // Variables del formulario
  late String _selectedStatus;
  late bool _isPainted;
  String _materialMode = 'filament';
  double _suggestedPrice = 0.0;
  int? _selectedClientId; // <--- NUEVO

  // Controladores básicos
  final _nameController = TextEditingController();
  final _platesController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidController = TextEditingController(text: '0.00');
  final _paintHoursController = TextEditingController(text: '1');

  // Controladores de Material
  int? _selectedResinId;
  final _resinGramsController = TextEditingController();
  final List<_FilamentEntry> _filamentEntries = [_FilamentEntry()];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final settings = await _settingsRepo.getAllSettings();
    _margenBeneficio = settings['margen_beneficio'] ?? 45.0;
    _costeHoraPintado = settings['coste_hora_pintado'] ?? 15.0;
    _costePlacaExtra = settings['coste_placa_extra'] ?? 2.50;

    final materials = await _materialRepo.getAllMaterials();
    _resins = materials.where((m) => m['type'] == 'resin').toList();
    _filaments = materials.where((m) => m['type'] == 'filament').toList();

    // Cargamos los clientes
    _clients = await _clientRepo.getAllClients();

    final order = widget.initialOrder;
    _nameController.text = order?['name'] ?? '';
    _platesController.text = (order?['plates'] ?? '1').toString();
    _selectedStatus = order?['status'] ?? 'Draft';
    _isPainted = order?['is_painted'] == 1;
    _selectedClientId =
        order?['client_id']; // Cargamos el cliente si ya existía

    if (order != null) {
      _priceController.text = (order['price'] as num).toStringAsFixed(2);
      _paidController.text = ((order['paid_amount'] ?? 0) as num)
          .toStringAsFixed(2);

      final items = await _orderRepo.getOrderItems(order['id']);
      if (items.isNotEmpty) {
        int firstMatId = items.first['material_id'];
        bool isResin = _resins.any((r) => r['id'] == firstMatId);

        if (isResin) {
          _materialMode = 'resin';
          _selectedResinId = firstMatId;
          _resinGramsController.text = items.first['grams_used'].toString();
        } else {
          _materialMode = 'filament';
          _filamentEntries.clear();
          for (var item in items) {
            final entry = _FilamentEntry();
            entry.materialId = item['material_id'];
            entry.gramsController.text = item['grams_used'].toString();
            _filamentEntries.add(entry);
          }
        }
      }
    }

    setState(() => _isLoading = false);
    _calculateEstimate();
  }

  void _calculateEstimate() {
    double costMaterial = 0.0;

    if (_materialMode == 'resin' && _selectedResinId != null) {
      final res = _resins.firstWhere((r) => r['id'] == _selectedResinId);
      double g = double.tryParse(_resinGramsController.text) ?? 0;
      costMaterial = (g / 1000) * (res['cost_per_kg'] as num);
    } else if (_materialMode == 'filament') {
      for (var entry in _filamentEntries) {
        if (entry.materialId != null) {
          final fil = _filaments.firstWhere((f) => f['id'] == entry.materialId);
          double g = double.tryParse(entry.gramsController.text) ?? 0;
          costMaterial += (g / 1000) * (fil['cost_per_kg'] as num);
        }
      }
    }

    double plates = double.tryParse(_platesController.text) ?? 1;
    double costPlates = (plates > 1) ? (plates - 1) * _costePlacaExtra : 0;

    double paintHours = double.tryParse(_paintHoursController.text) ?? 0;
    double costPaint = _isPainted ? (paintHours * _costeHoraPintado) : 0.0;

    setState(() {
      _suggestedPrice =
          (costMaterial + costPlates) * (1 + (_margenBeneficio / 100)) +
          costPaint;
    });
  }

  void _applySuggestedPrice() {
    setState(() {
      _priceController.text = _suggestedPrice.toStringAsFixed(2);
    });
  }

  // --- CREAR CLIENTE AL VUELO ---
  void _addNewClientOnTheFly() {
    showDialog(
      context: context,
      builder: (context) => ClientDialog(
        onSave: (newClient) async {
          int newId = await _clientRepo.insertClient(newClient);
          final updatedClients = await _clientRepo.getAllClients();
          setState(() {
            _clients = updatedClients;
            _selectedClientId = newId; // Lo dejamos seleccionado
          });
        },
      ),
    );
  }

  void _addNewMaterialOnTheFly(String type, Function(int) onSelected) {
    showDialog(
      context: context,
      builder: (context) => MaterialDialog(
        initialMaterial: {'type': type},
        onSave: (newMaterial) async {
          int newId = await _materialRepo.insertMaterial(newMaterial);
          final materials = await _materialRepo.getAllMaterials();
          setState(() {
            _resins = materials.where((m) => m['type'] == 'resin').toList();
            _filaments = materials
                .where((m) => m['type'] == 'filament')
                .toList();
          });
          onSelected(newId);
          _calculateEstimate();
        },
      ),
    );
  }

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

    double price = double.tryParse(_priceController.text) ?? 0.0;
    double paid = double.tryParse(_paidController.text) ?? 0.0;
    double pending = price - paid;
    bool isUnderpriced = price < (_suggestedPrice - 0.01) && price > 0;

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
              // --- ZONA 1: CLIENTE (NUEVO) ---
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedClientId,
                      decoration: const InputDecoration(
                        labelText: 'Cliente (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Sin asignar'),
                        ),
                        ..._clients.map(
                          (c) => DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text(c['name']),
                          ),
                        ),
                      ],
                      onChanged: _isLocked
                          ? null
                          : (v) => setState(() {
                              _selectedClientId = v;
                            }),
                    ),
                  ),
                  if (!_isLocked)
                    IconButton(
                      icon: const Icon(
                        Icons.person_add,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Crear nuevo cliente',
                      onPressed: _addNewClientOnTheFly,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // --- ZONA 2: PROYECTO Y ESTADO ---
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Proyecto',
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
                      items: () {
                        List<String> options = [
                          'Draft',
                          'Reserved',
                          'In Progress',
                          'Shipped',
                          'Canceled',
                        ];
                        if (_selectedStatus == 'Completed')
                          options.add('Completed');
                        return options
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList();
                      }(),
                      onChanged: _isLocked
                          ? null
                          : (v) => setState(() {
                              _selectedStatus = v!;
                            }),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // --- RESTO DEL FORMULARIO (Igual que antes) ---
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

              if (_materialMode == 'resin')
                _buildResinZone()
              else
                _buildFilamentZone(),

              const Divider(height: 32),

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

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Contabilidad del Pedido",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Sugerido: €${_suggestedPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (!_isLocked)
                              TextButton(
                                onPressed: _applySuggestedPrice,
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.only(left: 8),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Copiar al Final",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isUnderpriced)
                          const Text(
                            "⚠️ Vendiendo por debajo del sugerido",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.alertBajoStock,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pending > 0
                          ? AppColors.alertBajoStock.withOpacity(0.1)
                          : AppColors.statusCompletado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Pendiente: €${pending.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pending > 0
                            ? AppColors.alertBajoStock
                            : AppColors.statusCompletado,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      enabled: !_isLocked,
                      decoration: InputDecoration(
                        labelText: 'Precio Final (€)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.euro,
                          color: isUnderpriced
                              ? AppColors.alertBajoStock
                              : AppColors.primary,
                        ),
                      ),
                      style: TextStyle(
                        color: isUnderpriced
                            ? AppColors.alertBajoStock
                            : AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _paidController,
                      enabled: !_isLocked,
                      decoration: const InputDecoration(
                        labelText: 'Pagado / Adelanto (€)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.statusCompletado,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppColors.statusCompletado,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
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

  Widget _buildResinZone() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
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
              if (!_isLocked)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  tooltip: 'Añadir nueva resina',
                  onPressed: () => _addNewMaterialOnTheFly(
                    'resin',
                    (newId) => setState(() => _selectedResinId = newId),
                  ),
                ),
            ],
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
                  child: Row(
                    children: [
                      Expanded(
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
                      if (!_isLocked)
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Añadir nuevo filamento',
                          onPressed: () => _addNewMaterialOnTheFly(
                            'filament',
                            (newId) =>
                                setState(() => fEntry.materialId = newId),
                          ),
                        ),
                    ],
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

  void _saveOrder() {
    Map<String, dynamic> orderData = {
      'client_id': _selectedClientId, // <--- GUARDAMOS EL CLIENTE
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'paid_amount': double.tryParse(_paidController.text) ?? 0.0,
      'date':
          widget.initialOrder?['date'] ??
          DateTime.now().toString().split(' ')[0],
      'status': _selectedStatus,
      'grams': 0.0,
      'plates': int.tryParse(_platesController.text) ?? 1,
      'is_painted': _isPainted ? 1 : 0,
    };

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

    orderData['items'] = items;
    widget.onSave(orderData);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
