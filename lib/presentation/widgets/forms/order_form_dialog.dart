import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/number_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/strings.dart';
import '../../../data/service_locator.dart';
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

  // ==================== CONFIGURACIÓN GLOBAL ====================
  //default values, se cargarán desde la base de datos al iniciar el formulario
  double _margenBeneficio = 200.0;
  double _costeHoraPintado = 8.0;
  double _costePlacaExtra = 0.20;

  // ==================== DATOS DE BASE DE DATOS ====================
  List<Map<String, dynamic>> _materials = []; // ¡Lista unificada!
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _extras = [];

  // extras seleccionados: extraId -> cantidad
  final Map<int, int> _selectedExtras = {};

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
  double _totalCost = 0.0;

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
    final settings = await ServiceLocator.settingsRepo.getAllSettings();
    _margenBeneficio =
        settings[SettingKeys.margenBeneficio] ?? _margenBeneficio;
    _costeHoraPintado =
        settings[SettingKeys.costeHoraPintado] ?? _costeHoraPintado;
    _costePlacaExtra =
        settings[SettingKeys.costePlacaExtra] ?? _costePlacaExtra;

    // Cargar materiales (Todos juntos)
    _materials = await ServiceLocator.materialRepo.getAllMaterials();
    _clients = await ServiceLocator.clientRepo.getAllClients();
    _extras = await ServiceLocator.extrasRepo.getAllExtras();

    final order = widget.initialOrder;
    if (order != null) {
      _nameController.text = order['name'] ?? '';
      _selectedStatus = order['status'] ?? OrderStatus.draft;
      _isPainted = order['is_painted'] == 1;
      _selectedClientId = order['client_id'];
      _priceController.text = (order['price'] as num).toStringAsFixed(2);
      _paidController.text = ((order['paid_amount'] ?? 0) as num)
          .toStringAsFixed(2);

      // Cargar placas desde la v6 de la base de datos
      final loadedPlates = await ServiceLocator.orderRepo.getOrderPlates(
        order['id'],
      );
      _plates = loadedPlates.map((p) => Map<String, dynamic>.from(p)).toList();
      _platesController.text = _plates.length.toString();
      // Si el pedido guardado incluye extras, cargarlos
      if (order['extras'] != null && order['extras'] is List) {
        for (var e in order['extras']) {
          final id = e['id'] as int?;
          final qty = e['quantity'] as int? ?? 0;
          if (id != null && qty > 0) _selectedExtras[id] = qty;
        }
      }
    } else {
      _selectedStatus = OrderStatus.draft;
      _isPainted = false;
      _selectedClientId = null;
    }

    setState(() => _isLoading = false);
    _calculateEstimate();
  }

  // ==================== CÁLCULOS (MOTOR ACTUALIZADO) ====================
  void _calculateEstimate() {
    double costMaterial = 0.0;
    double costePlacaExtraAcumulado = 0.0;
    double extrasCost = 0.0;

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
          //explonencial por placas extras
          costePlacaExtraAcumulado +=
              _costePlacaExtra * (1 + (_plates.length - 1) * 0.1);
          costMaterial += (g / 1000) * costPerKg + costePlacaExtraAcumulado;
          // Si tienes coste eléctrico/hora, lo podrías sumar aquí usando plate['minutes']
        }
      }
    }

    // 2. Calcular otros costes (Pintura)
    double paintHours = parseDecimal(_paintHoursController.text);
    double costPaint = _isPainted ? (paintHours * _costeHoraPintado) : 0.0;

    // 3. Calcular extras seleccionados
    for (var entry in _selectedExtras.entries) {
      final ex = _extras.firstWhere(
        (x) => x['id'] == entry.key,
        orElse: () => {},
      );
      if (ex.isNotEmpty) {
        double price = (ex['price'] as num).toDouble();
        extrasCost += price * (entry.value);
      }
    }

    setState(() {
      _totalCost = costMaterial + costPaint + extrasCost;
      _suggestedPrice =
          (costMaterial + extrasCost) * (1 + (_margenBeneficio / 100)) +
          costPaint;
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
      _selectedStatus == OrderStatus.completed ||
      _selectedStatus == OrderStatus.shipped;

  void _onAddNewMaterial(Function(int) onSelected) {
    showDialog(
      context: context,
      builder: (context) => MaterialDialog(
        onSave: (newMaterial) async {
          int newId = await ServiceLocator.materialRepo.insertMaterial(
            newMaterial,
          );
          _materials = await ServiceLocator.materialRepo.getAllMaterials();
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
          int newId = await ServiceLocator.clientRepo.insertClient(newClient);
          final updatedClients = await ServiceLocator.clientRepo
              .getAllClients();
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
      'price': parseDecimal(_priceController.text),
      'paid_amount': parseDecimal(_paidController.text),
      'date':
          widget.initialOrder?['date'] ??
          DateTime.now().toString().split(' ')[0],
      'status': _selectedStatus,
      'is_painted': _isPainted ? 1 : 0,
      'notes': widget.initialOrder?['notes'] ?? '',
      'plates': _plates, // Pasamos la lista de placas al repositorio
      'extras': _selectedExtras.entries
          .map((e) => {'id': e.key, 'quantity': e.value})
          .toList(),
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
          Text(widget.initialOrder == null ? AppStrings.newOrder : AppStrings.editOrder),
          if (_isLocked)
            const Chip(
              label: Text(AppStrings.blocked, style: TextStyle(fontSize: 10)),
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
                        labelText: AppStrings.clientOptional,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text(AppStrings.unassigned),
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
                      tooltip: AppStrings.createNewClient,
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
                        labelText: AppStrings.projectName,
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
                        labelText: AppStrings.status,
                        border: OutlineInputBorder(),
                      ),
                      items: () {
                        List<String> options = [
                          OrderStatus.draft,
                          OrderStatus.reserved,
                          OrderStatus.inProgress,
                          OrderStatus.shipped,
                          OrderStatus.canceled,
                        ];
                        if (_selectedStatus == OrderStatus.completed) {
                          options.add(OrderStatus.completed);
                        }
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
              const SizedBox(height: 16),

              // --- ZONA 3.1: EXTRAS ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text(
                        AppStrings.extrasTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_extras.isEmpty)
                        const Text(AppStrings.noExtrasDefined),
                      ..._extras.map((ex) {
                        final id = ex['id'] as int;
                        final qty = _selectedExtras[id] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(child: Text('${ex['name']}')),
                              Text(
                                '€${(ex['price'] as num).toStringAsFixed(2)}',
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _isLocked || qty <= 0
                                    ? null
                                    : () => setState(() {
                                        _selectedExtras[id] = qty - 1;
                                        if (_selectedExtras[id] == 0) {
                                          _selectedExtras.remove(id);
                                        }
                                        _calculateEstimate();
                                      }),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(qty.toString()),
                              IconButton(
                                onPressed: _isLocked
                                    ? null
                                    : () => setState(() {
                                        final newQty = (qty) + 1;
                                        _selectedExtras[id] = newQty;
                                        _calculateEstimate();
                                      }),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
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
                totalCost: _totalCost,
                margenBeneficio: _margenBeneficio,
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
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
          ),
          onPressed: _isLocked ? null : _saveOrder,
          child: const Text(AppStrings.saveOrder),
        ),
      ],
    );
  }
}
