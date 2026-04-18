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
  final double _costePlacaExtra =
      2.50; // Ya no aplica tanto, pero lo mantenemos por si acaso

  // ==================== DATOS DE BASE DE DATOS ====================
  List<Map<String, dynamic>> _materials = []; // ¡Lista unificada!
  List<Map<String, dynamic>> _clients = [];

  // ==================== ESTADO DEL FORMULARIO ====================
  late String _selectedStatus;
  late bool _isPainted;
  int? _selectedClientId;

  final _nameController = TextEditingController();
  final _platesController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _paidController = TextEditingController(text: '0.00');
  final _paintHoursController = TextEditingController(text: '1');

  // LA NUEVA JOYA: La lista de placas
  List<Map<String, dynamic>> _plates = [];

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
    super.dispose();
  }

  // ==================== CARGA DE DATOS INICIALES ====================
  Future<void> _loadInitialData() async {
    final settings = await _settingsRepo.getAllSettings();
    _margenBeneficio = settings['margen_beneficio'] ?? 45.0;
    _costeHoraPintado = settings['coste_hora_pintado'] ?? 15.0;

    // Cargar materiales (Todos juntos)
    _materials = await _materialRepo.getAllMaterials();
    _clients = await _clientRepo.getAllClients();

    final order = widget.initialOrder;
    if (order != null) {
      _nameController.text = order['name'] ?? '';
      _selectedStatus = order['status'] ?? 'Draft';
      _isPainted = order['is_painted'] == 1;
      _selectedClientId = order['client_id'];
      _priceController.text = (order['price'] as num).toStringAsFixed(2);
      _paidController.text = ((order['paid_amount'] ?? 0) as num)
          .toStringAsFixed(2);

      // Cargar placas desde la v6 de la base de datos
      final loadedPlates = await _orderRepo.getOrderPlates(order['id']);
      _plates = loadedPlates.map((p) => Map<String, dynamic>.from(p)).toList();
      _platesController.text = _plates.length.toString();
    } else {
      _selectedStatus = 'Draft';
      _isPainted = false;
      _selectedClientId = null;
    }

    setState(() => _isLoading = false);
    _calculateEstimate();
  }

  // ==================== CÁLCULOS (MOTOR ACTUALIZADO) ====================
  void _calculateEstimate() {
    double costMaterial = 0.0;

    // 1. Calcular el coste de cada placa sumada
    for (var plate in _plates) {
      if (plate['material_id'] != null) {
        final mat = _materials.firstWhere(
          (m) => m['id'] == plate['material_id'],
          orElse: () => {},
        );
        if (mat.isNotEmpty) {
          double g = (plate['grams'] as num).toDouble();
          double costPerKg = (mat['cost_per_kg'] as num).toDouble();
          costMaterial += (g / 1000) * costPerKg;
          // Si tienes coste eléctrico/hora, lo podrías sumar aquí usando plate['minutes']
        }
      }
    }

    // 2. Calcular otros costes (Pintura)
    double paintHours = double.tryParse(_paintHoursController.text) ?? 0;
    double costPaint = _isPainted ? (paintHours * _costeHoraPintado) : 0.0;

    setState(() {
      _suggestedPrice =
          (costMaterial) * (1 + (_margenBeneficio / 100)) + costPaint;
      _platesController.text = _plates.length
          .toString(); // Actualizamos el contador visual
    });
  }

  void _applySuggestedPrice() {
    setState(() {
      _priceController.text = _suggestedPrice.toStringAsFixed(2);
    });
  }

  // ==================== MANEJO DE ESTADO ====================
  bool get _isLocked =>
      _selectedStatus == 'Completed' || _selectedStatus == 'Shipped';

  void _onAddNewMaterial(Function(int) onSelected) {
    showDialog(
      context: context,
      builder: (context) => MaterialDialog(
        onSave: (newMaterial) async {
          int newId = await _materialRepo.insertMaterial(newMaterial);
          _materials = await _materialRepo.getAllMaterials();
          setState(() {
            onSelected(newId);
            _calculateEstimate();
          });
        },
      ),
    );
  }

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
      if (widget.initialOrder != null)
        'id': widget.initialOrder!['id'], // Mantener ID si editamos
      'client_id': _selectedClientId,
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'paid_amount': double.tryParse(_paidController.text) ?? 0.0,
      'date':
          widget.initialOrder?['date'] ??
          DateTime.now().toString().split(' ')[0],
      'status': _selectedStatus,
      'is_painted': _isPainted ? 1 : 0,
      'notes': widget.initialOrder?['notes'] ?? '',
      'plates': _plates, // Pasamos la lista de placas al repositorio
    };

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
                          : (v) => setState(() => _selectedClientId = v),
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
                          : (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // --- ZONA 3: PLACAS Y MATERIALES ---
              MaterialFormSection(
                plates: _plates,
                availableMaterials: _materials,
                isLocked: _isLocked,
                onPlatesChanged: (updatedPlates) {
                  setState(() {
                    _plates = updatedPlates;
                    _calculateEstimate();
                  });
                },
                onAddNewMaterial: _onAddNewMaterial,
              ),
              const Divider(height: 32),

              // --- ZONA 4: FINANZAS ---
              FinanceFormSection(
                platesController:
                    _platesController, // Solo lectura ahora, lo actualiza el código
                paintHoursController: _paintHoursController,
                priceController: _priceController,
                paidController: _paidController,
                isPainted: _isPainted,
                suggestedPrice: _suggestedPrice,
                isLocked: _isLocked,
                onPaintedChanged: (val) => setState(() {
                  _isPainted = val;
                  _calculateEstimate();
                }),
                onPlatesChanged:
                    (val) {}, // Desactivado porque las placas se manejan arriba
                onPaintHoursChanged: (val) => _calculateEstimate(),
                onPriceChanged: (val) => setState(() {}),
                onPaidChanged: (val) => setState(() {}),
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
