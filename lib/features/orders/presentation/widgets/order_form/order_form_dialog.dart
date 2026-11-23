import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/loading_dialog.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/clients/presentation/widgets/client_form_dialog.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_dialog.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/extras_section.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/finance_section.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/plate_draft.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/plates_section.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Lo que devuelve el formulario al guardar.
class OrderFormResult {
  const OrderFormResult({
    required this.order,
    required this.plates,
    required this.extras,
  });

  final Order order;
  final List<OrderPlate> plates;
  final List<OrderExtraLine> extras;
}

/// Formulario de alta/edición de pedido con calculadora de precio.
///
/// Si el pedido está cerrado (completado o enviado) se muestra en solo lectura.
class OrderFormDialog extends StatefulWidget {
  const OrderFormDialog({super.key, required this.onSave, this.initialOrder});

  final ValueChanged<OrderFormResult> onSave;
  final Order? initialOrder;

  @override
  State<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<OrderFormDialog> {
  bool _isLoading = true;

  // Datos de referencia
  PricingSettings _settings = const PricingSettings();
  List<PrintMaterial> _materials = [];
  List<Client> _clients = [];
  List<Extra> _extras = [];

  // Estado del formulario
  OrderStatus _status = OrderStatus.draft;
  bool _isPainted = false;
  int? _clientId;
  List<PlateDraft> _plates = [];

  /// Cantidad por id de pieza (solo > 0).
  final Map<int, int> _selectedExtras = {};

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidController = TextEditingController(text: '0.00');
  final _paintHoursController = TextEditingController(text: '1');

  PriceEstimate _estimate = PriceEstimate.zero;

  bool get _isLocked => _status.isLocked;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _paidController.dispose();
    _paintHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final settings = await ServiceLocator.settings.getPricingSettings();
    final materials = await ServiceLocator.materials.getAll();
    final clients = await ServiceLocator.clients.getAll();
    final extras = await ServiceLocator.extras.getAll();

    final order = widget.initialOrder;
    var plates = <PlateDraft>[];
    if (order != null) {
      final saved = await ServiceLocator.orders.getPlates(order.id!);
      plates = saved.map(PlateDraft.fromPlate).toList();
    }
    if (!mounted) return;

    setState(() {
      _settings = settings;
      _materials = materials;
      _clients = clients;
      _extras = extras;
      _plates = plates;
      if (order != null) {
        _nameController.text = order.name;
        _status = order.status;
        _isPainted = order.isPainted;
        _clientId = order.clientId;
        _priceController.text = order.price.toStringAsFixed(2);
        _paidController.text = order.paidAmount.toStringAsFixed(2);
      }
      _isLoading = false;
    });
    _recalculate();
  }

  void _recalculate() {
    setState(() {
      _estimate = PricingCalculator.estimate(
        plates: [for (final p in _plates) p.toPricing()],
        materialCostPerKg: {for (final m in _materials) m.id!: m.costPerKg},
        extraUnitPrices: {for (final e in _extras) e.id!: e.unitPrice},
        selectedExtras: _selectedExtras,
        isPainted: _isPainted,
        paintHours: parseDecimal(_paintHoursController.text),
        settings: _settings,
      );
    });
  }

  // ==================== ACCIONES ====================

  void _addPlate() {
    _plates.add(
      PlateDraft(
        name: AppStrings.defaultPlateName(_plates.length + 1),
        materialId: _materials.isNotEmpty ? _materials.first.id : null,
      ),
    );
    _recalculate();
  }

  void _removePlate(PlateDraft plate) {
    _plates.remove(plate);
    _recalculate();
  }

  void _setExtraQuantity(int extraId, int quantity) {
    if (quantity <= 0) {
      _selectedExtras.remove(extraId);
    } else {
      _selectedExtras[extraId] = quantity;
    }
    _recalculate();
  }

  void _addNewMaterial(PlateDraft plate) {
    showDialog(
      context: context,
      builder: (_) => MaterialDialog(
        onSave: (material) async {
          final newId = await ServiceLocator.materials.save(material);
          final materials = await ServiceLocator.materials.getAll();
          if (!mounted) return;
          _materials = materials;
          plate.materialId = newId;
          _recalculate();
        },
      ),
    );
  }

  void _addNewClient() {
    showDialog(
      context: context,
      builder: (_) => ClientFormDialog(
        onSave: (client) async {
          final newId = await ServiceLocator.clients.save(client);
          final clients = await ServiceLocator.clients.getAll();
          if (!mounted) return;
          setState(() {
            _clients = clients;
            _clientId = newId;
          });
        },
      ),
    );
  }

  void _save() {
    final initial = widget.initialOrder;
    widget.onSave(
      OrderFormResult(
        order: Order(
          id: initial?.id,
          clientId: _clientId,
          name: _nameController.text,
          price: parseDecimal(_priceController.text),
          paidAmount: parseDecimal(_paidController.text),
          date: initial?.date ?? todayIsoDate(),
          status: _status,
          isPainted: _isPainted,
          notes: initial?.notes ?? '',
        ),
        plates: [for (final p in _plates) p.toPlate()],
        extras: [
          for (final e in _selectedExtras.entries)
            OrderExtraLine(extraId: e.key, quantity: e.value),
        ],
      ),
    );
    Navigator.pop(context);
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingDialog();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.initialOrder == null
                ? AppStrings.newOrder
                : AppStrings.editOrder,
          ),
          if (_isLocked)
            const Chip(
              label: Text(AppStrings.locked, style: TextStyle(fontSize: 10)),
              backgroundColor: AppColors.success,
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
              _buildClientRow(),
              const SizedBox(height: 16),
              _buildNameAndStatusRow(),
              const Divider(height: 32),
              PlatesSection(
                plates: _plates,
                materials: _materials,
                isLocked: _isLocked,
                onChanged: _recalculate,
                onAddPlate: _addPlate,
                onRemovePlate: _removePlate,
                onAddNewMaterial: _addNewMaterial,
              ),
              const SizedBox(height: 16),
              ExtrasSection(
                extras: _extras,
                selected: _selectedExtras,
                isLocked: _isLocked,
                onQuantityChanged: _setExtraQuantity,
              ),
              const Divider(height: 32),
              FinanceSection(
                platesCount: _plates.length,
                isPainted: _isPainted,
                paintHoursController: _paintHoursController,
                priceController: _priceController,
                paidController: _paidController,
                estimate: _estimate,
                isLocked: _isLocked,
                onPaintedChanged: (value) {
                  _isPainted = value;
                  _recalculate();
                },
                onPaintHoursChanged: _recalculate,
                onPriceChanged: () => setState(() {}),
                onApplySuggestedPrice: () => setState(() {
                  _priceController.text = _estimate.suggestedPrice
                      .toStringAsFixed(2);
                }),
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
          style: AppButtonStyles.primary,
          onPressed: _isLocked ? null : _save,
          child: const Text(AppStrings.saveOrder),
        ),
      ],
    );
  }

  Widget _buildClientRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            // La clave refleja el cliente recién creado desde aquí.
            key: ValueKey(_clientId),
            initialValue: _clientId,
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
              for (final c in _clients)
                DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
            ],
            onChanged: _isLocked ? null : (v) => setState(() => _clientId = v),
          ),
        ),
        if (!_isLocked)
          IconButton(
            icon: const Icon(Icons.person_add, color: AppColors.primary),
            tooltip: AppStrings.createNewClient,
            onPressed: _addNewClient,
          ),
      ],
    );
  }

  Widget _buildNameAndStatusRow() {
    final statusOptions = [
      ...OrderStatus.manualChoices,
      if (_status == OrderStatus.completed) OrderStatus.completed,
    ];
    return Row(
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
          child: DropdownButtonFormField<OrderStatus>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: AppStrings.status,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in statusOptions)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: _isLocked ? null : (v) => setState(() => _status = v!),
          ),
        ),
      ],
    );
  }
}
