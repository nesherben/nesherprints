import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/material_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/client_repository.dart';
import '../client_dialog.dart';
import '../material_dialog.dart';
import 'material_form_section.dart';
import 'finance_form_section.dart';
import 'filament_entry.dart';

class OrderFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialOrder;

  const OrderFormDialog({super.key, required this.onSave, this.initialOrder});

  @override
  State<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<OrderFormDialog> {
  // ==================== ESTADO DE CARGA ====================
  bool _isLoading = true;

  // ==================== REPOSITORIOS ====================
  final _settingsRepo = SettingsRepository();
  final _materialRepo = MaterialRepository();
  final _orderRepo = OrderRepository();
  final _clientRepo = ClientRepository();

  // ==================== CONFIGURACIÓN GLOBAL ====================
  double _margenBeneficio = 45.0;
  double _costeHoraPintado = 15.0;
  double _costePlacaExtra = 2.50;

  // ==================== DATOS DE BASE DE DATOS ====================
  List<Map<String, dynamic>> _resins = [];
  List<Map<String, dynamic>> _filaments = [];
  List<Map<String, dynamic>> _clients = [];

  // ==================== ESTADO DEL FORMULARIO BÁSICO ====================
  late String _selectedStatus;
  late bool _isPainted;
  int? _selectedClientId;

  final _nameController = TextEditingController();
  final _platesController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidController = TextEditingController(text: '0.00');
  final _paintHoursController = TextEditingController(text: '1');

  // ==================== ESTADO DEL FORMULARIO MATERIAL ====================
  String _materialMode = 'filament';
  int? _selectedResinId;
  final _resinGramsController = TextEditingController();
  final List<FilamentEntry> _filamentEntries = [FilamentEntry()];

  // ==================== ESTADO CALCULADO ====================
  double _suggestedPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _platesController.dispose();
    _priceController.dispose();
    _paidController.dispose();
    _paintHoursController.dispose();
    _resinGramsController.dispose();
    for (var entry in _filamentEntries) {
      entry.gramsController.dispose();
    }
    super.dispose();
  }

  // ==================== CARGA DE DATOS INICIALES ====================
  Future<void> _loadInitialData() async {
    // 1. Cargar configuración global
    final settings = await _settingsRepo.getAllSettings();
    _margenBeneficio = settings['margen_beneficio'] ?? 45.0;
    _costeHoraPintado = settings['coste_hora_pintado'] ?? 15.0;
    _costePlacaExtra = settings['coste_placa_extra'] ?? 2.50;

    // 2. Cargar materiales
    final materials = await _materialRepo.getAllMaterials();
    _resins = materials.where((m) => m['type'] == 'resin').toList();
    _filaments = materials.where((m) => m['type'] == 'filament').toList();

    // 3. Cargar clientes
    _clients = await _clientRepo.getAllClients();

    // 4. Si es edición, cargar datos del pedido existente
    final order = widget.initialOrder;
    if (order != null) {
      _nameController.text = order['name'] ?? '';
      _platesController.text = (order['plates'] ?? '1').toString();
      _selectedStatus = order['status'] ?? 'Draft';
      _isPainted = order['is_painted'] == 1;
      _selectedClientId = order['client_id'];
      _priceController.text = (order['price'] as num).toStringAsFixed(2);
      _paidController.text = ((order['paid_amount'] ?? 0) as num)
          .toStringAsFixed(2);

      // Cargar materiales asociados
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
            final entry = FilamentEntry();
            entry.materialId = item['material_id'];
            entry.gramsController.text = item['grams_used'].toString();
            _filamentEntries.add(entry);
          }
        }
      }
    } else {
      // Nueva orden
      _selectedStatus = 'Draft';
      _isPainted = false;
      _selectedClientId = null;
    }

    setState(() => _isLoading = false);
    _calculateEstimate();
  }

  // ==================== CÁLCULOS ====================
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

  // ==================== MANEJO DE ESTADO DEL FORMULARIO ====================
  bool get _isLocked =>
      _selectedStatus == 'Completed' || _selectedStatus == 'Shipped';

  // --- Material Section Callbacks ---
  void _onMaterialModeChanged(String newMode) {
    setState(() {
      _materialMode = newMode;
      _calculateEstimate();
    });
  }

  void _onResinSelected(int? resinId) {
    setState(() {
      _selectedResinId = resinId;
      _calculateEstimate();
    });
  }

  void _onFilamentSelected(int index) {
    setState(() {
      _calculateEstimate();
    });
  }

  void _onGramsChanged(String value) {
    _calculateEstimate();
  }

  void _onAddFilament() {
    setState(() {
      _filamentEntries.add(FilamentEntry());
      _calculateEstimate();
    });
  }

  void _onRemoveFilament(int index) {
    setState(() {
      _filamentEntries.removeAt(index);
      _calculateEstimate();
    });
  }

  void _onAddNewMaterial(String type, Function(int) onSelected) {
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

  // --- Finance Section Callbacks ---
  void _onPaintedChanged(bool value) {
    setState(() {
      _isPainted = value;
      _calculateEstimate();
    });
  }

  void _onPlatesChanged(String value) {
    _calculateEstimate();
  }

  void _onPaintHoursChanged(String value) {
    _calculateEstimate();
  }

  void _onPriceChanged(String value) {
    setState(() {});
  }

  void _onPaidChanged(String value) {
    setState(() {});
  }

  // --- Dialogs para crear clientes al vuelo ---
  void _showClientDialog() {
    showDialog(
      context: context,
      builder: (context) => ClientDialog(
        onSave: (newClient) async {
          int newId = await _clientRepo.insertClient(newClient);
          final updatedClients = await _clientRepo.getAllClients();
          setState(() {
            _clients = updatedClients;
            _selectedClientId = newId;
          });
        },
      ),
    );
  }

  // ==================== GUARDAR PEDIDO ====================
  void _saveOrder() {
    Map<String, dynamic> orderData = {
      'client_id': _selectedClientId,
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

  // ==================== BUILD ====================
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
              // --- ZONA 1: CLIENTE ---
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
                      onPressed: _showClientDialog,
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
                        if (_selectedStatus == 'Completed') {
                          options.add('Completed');
                        }
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

              // --- ZONA 3: MATERIAL (COMPONENTE SEPARADO) ---
              MaterialFormSection(
                materialMode: _materialMode,
                selectedResinId: _selectedResinId,
                resins: _resins,
                filaments: _filaments,
                resinGramsController: _resinGramsController,
                filamentEntries: _filamentEntries,
                isLocked: _isLocked,
                onMaterialModeChanged: _onMaterialModeChanged,
                onResinSelected: _onResinSelected,
                onFilamentSelected: _onFilamentSelected,
                onGramsChanged: _onGramsChanged,
                onAddFilament: _onAddFilament,
                onRemoveFilament: _onRemoveFilament,
                onAddNewMaterial: _onAddNewMaterial,
              ),
              const Divider(height: 32),

              // --- ZONA 4: FINANZAS (COMPONENTE SEPARADO) ---
              FinanceFormSection(
                platesController: _platesController,
                paintHoursController: _paintHoursController,
                priceController: _priceController,
                paidController: _paidController,
                isPainted: _isPainted,
                suggestedPrice: _suggestedPrice,
                isLocked: _isLocked,
                onPaintedChanged: _onPaintedChanged,
                onPlatesChanged: _onPlatesChanged,
                onPaintHoursChanged: _onPaintHoursChanged,
                onPriceChanged: _onPriceChanged,
                onPaidChanged: _onPaidChanged,
                onApplySuggestedPrice: _applySuggestedPrice,
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
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
          ),
          onPressed: _isLocked ? null : _saveOrder,
          child: const Text('Guardar Pedido'),
        ),
      ],
    );
  }
}
