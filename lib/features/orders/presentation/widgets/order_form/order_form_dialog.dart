import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/loading_dialog.dart';
import 'package:nesherprints/core/widgets/section_card.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/clients/presentation/widgets/client_form_dialog.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/inventory/presentation/widgets/material_dialog.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_rules.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/domain/paint_detail.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/orders/presentation/status_style.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/extras_section.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/plate_draft.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/plates_section.dart';
import 'package:nesherprints/features/orders/presentation/widgets/order_form/price_summary_panel.dart';
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
/// - [initialOrder]: edita ese pedido (solo lectura si está completado/enviado).
/// - [duplicateOf]: pedido nuevo con las placas y piezas de otro.
class OrderFormDialog extends StatefulWidget {
  const OrderFormDialog({
    super.key,
    required this.onSave,
    this.initialOrder,
    this.duplicateOf,
  });

  /// Guarda el resultado. Si lanza, el diálogo sigue abierto y muestra el
  /// error sin perder lo escrito.
  final Future<void> Function(OrderFormResult result) onSave;
  final Order? initialOrder;
  final Order? duplicateOf;

  @override
  State<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<OrderFormDialog> {
  bool _isLoading = true;
  bool _saving = false;

  /// Errores de validación mostrados en el pie (tras un intento de guardar).
  List<String> _errors = [];
  bool _attempted = false;

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

  /// Precio unitario ya registrado de las piezas que el pedido tenía.
  final Map<int, double> _lockedExtraPrices = {};

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidController = TextEditingController(text: '0');
  final _attemptsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  /// Hay cambios sin guardar (para avisar al cerrar).
  bool _dirty = false;

  PriceEstimate _estimate = PriceEstimate.zero;

  /// Detalle de la figura; solo cuenta si [_isPainted].
  PaintDetail _paintDetail = PaintDetail.normal;

  bool get _isEditing => widget.initialOrder != null;
  bool get _isLocked => _isEditing && _status.isLocked;

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
    _attemptsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final settings = await ServiceLocator.settings.getPricingSettings();
      final materials = await ServiceLocator.materials.getAll();
      final clients = await ServiceLocator.clients.getAll();
      final extras = await ServiceLocator.extras.getAll();

      final source = widget.initialOrder ?? widget.duplicateOf;
      var plates = <PlateDraft>[];
      var lines = <OrderExtraLine>[];
      if (source != null) {
        final saved = await ServiceLocator.orders.getPlates(source.id!);
        // Al duplicar, las placas son nuevas (sin el id de las originales).
        plates = [
          for (final p in saved)
            _isEditing
                ? PlateDraft.fromPlate(p)
                : PlateDraft.fromPlate(p).duplicate(p.name),
        ];
        lines = await ServiceLocator.orders.getExtras(source.id!);
      }
      if (!mounted) return;

      setState(() {
        _settings = settings;
        _materials = materials;
        _clients = clients;
        _extras = extras;
        _plates = plates;
        if (source != null) {
          final duplicating = !_isEditing;
          _nameController.text = duplicating
              ? '${source.name}${AppStrings.copySuffix}'
              : source.name;
          _status = duplicating ? OrderStatus.draft : source.status;
          _isPainted = source.isPainted;
          _clientId = source.clientId;
          _priceController.text = source.price.toStringAsFixed(2);
          _paidController.text = duplicating
              ? '0'
              : source.paidAmount.toStringAsFixed(2);
          _paintDetail = source.paintDetail;
          if (!duplicating) _notesController.text = source.notes;
          _attemptsController.text = formatInputNumber(source.attempts);
          for (final line in lines) {
            if (line.quantity <= 0) continue;
            _selectedExtras[line.extraId] = line.quantity;
            if (!duplicating && line.unitPrice != null) {
              _lockedExtraPrices[line.extraId] = line.unitPrice!;
            }
          }
        }
        _isLoading = false;
      });
      _recalculate();
      _dirty = false;
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AppFeedback.failure(context, e);
    }
  }

  // ==================== CÁLCULO ====================

  Map<int, double> get _extraPrices => {
    for (final e in _extras) e.id!: _lockedExtraPrices[e.id] ?? e.unitPrice,
  };

  double get _attempts => parseDecimal(_attemptsController.text, fallback: 1);

  void _recalculate() {
    setState(() {
      _estimate = PricingCalculator.estimate(
        plates: [for (final p in _plates) p.toPricing()],
        materialCostPerKg: {for (final m in _materials) m.id!: m.costPerKg},
        extraUnitPrices: _extraPrices,
        selectedExtras: _selectedExtras,
        attempts: _attempts,
        paintDetail: _isPainted ? _paintDetail : null,
        settings: _settings,
      );
      _dirty = true;
      if (_attempted) _errors = _validate();
    });
  }

  /// Refresca lo que depende de los campos de texto sin recalcular el precio.
  void _onFieldChanged() => setState(() {
    _dirty = true;
    if (_attempted) _errors = _validate();
  });

  // ==================== ACCIONES ====================

  bool get _needsDiscardConfirm => _dirty && !_saving && !_isLocked;

  /// Cierra el diálogo; si hay cambios sin guardar, pregunta antes.
  Future<void> _close() async {
    if (_needsDiscardConfirm) {
      final discard = await showConfirmDialog(
        context,
        title: AppStrings.discardTitle,
        message: AppStrings.discardMessage,
        confirmText: AppStrings.discard,
        cancelText: AppStrings.keepEditing,
        color: AppColors.danger,
        icon: Icons.delete_outline,
      );
      if (!discard || !mounted) return;
    }
    Navigator.pop(context);
  }

  void _addPlate() {
    _plates.add(
      PlateDraft(
        name: AppStrings.defaultPlateName(_plates.length + 1),
        materialId: _plates.isNotEmpty
            ? _plates.last.materialId
            : (_materials.isNotEmpty ? _materials.first.id : null),
      ),
    );
    _recalculate();
  }

  void _removePlate(PlateDraft plate) {
    _plates.remove(plate);
    _recalculate();
  }

  void _duplicatePlate(PlateDraft plate) {
    final index = _plates.indexOf(plate);
    _plates.insert(
      index + 1,
      plate.duplicate(AppStrings.defaultPlateName(_plates.length + 1)),
    );
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
          try {
            final newId = await ServiceLocator.materials.save(material);
            final materials = await ServiceLocator.materials.getAll();
            if (!mounted) return;
            _materials = materials;
            plate.materialId = newId;
            _recalculate();
          } catch (e) {
            if (mounted) AppFeedback.failure(context, e);
          }
        },
      ),
    );
  }

  void _addNewClient() {
    showDialog(
      context: context,
      builder: (_) => ClientFormDialog(
        onSave: (client) async {
          try {
            final newId = await ServiceLocator.clients.save(client);
            final clients = await ServiceLocator.clients.getAll();
            if (!mounted) return;
            setState(() {
              _clients = clients;
              _clientId = newId;
            });
          } catch (e) {
            if (mounted) AppFeedback.failure(context, e);
          }
        },
      ),
    );
  }

  // ==================== GUARDADO ====================

  Order _buildOrder() {
    final initial = widget.initialOrder;
    return Order(
      id: initial?.id,
      clientId: _clientId,
      name: _nameController.text.trim(),
      price: parseDecimal(_priceController.text),
      paidAmount: parseDecimal(_paidController.text),
      date: initial?.date ?? todayIsoDate(),
      status: _status,
      isPainted: _isPainted,
      notes: _notesController.text.trim(),
      attempts: _attempts,
      paintDetail: _paintDetail,
      costOverride: OrderRules.costOverrideOnSave(initial),
    );
  }

  List<String> _validate() => OrderRules.validateForm(_buildOrder(), [
    for (final p in _plates) p.toPlate(),
  ]);

  Future<void> _save() async {
    if (_saving || _isLocked) return;
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() {
        _attempted = true;
        _errors = errors;
      });
      return;
    }
    setState(() {
      _errors = [];
      _saving = true;
    });
    try {
      await widget.onSave(
        OrderFormResult(
          order: _buildOrder(),
          plates: [for (final p in _plates) p.toPlate()],
          extras: [
            for (final e in _selectedExtras.entries)
              OrderExtraLine(extraId: e.key, quantity: e.value),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _attempted = true;
        _errors = [AppFeedback.describe(e)];
      });
    }
  }

  // ==================== UI ====================

  String get _title {
    if (_isLocked) return AppStrings.viewOrder;
    if (_isEditing) return AppStrings.editOrder;
    if (widget.duplicateOf != null) return AppStrings.duplicateOrderTitle;
    return AppStrings.newOrder;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingDialog();

    final initial = widget.initialOrder;
    return PopScope(
      canPop: !_needsDiscardConfirm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        },
        child: AppDialogFrame(
          title: _title,
          subtitle: initial == null
              ? null
              : AppStrings.orderSubtitle(initial.id!, initial.date),
          icon: Icons.receipt_long_outlined,
          width: 1160,
          scrollable: false,
          padding: EdgeInsets.zero,
          headerTrailing: _buildStatusHeader(),
          footerLeading: _buildErrorSummary(),
          actions: [
            OutlinedButton(
              onPressed: _close,
              child: Text(_isLocked ? AppStrings.close : AppStrings.cancel),
            ),
            if (!_isLocked)
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_saving ? AppStrings.saving : AppStrings.saveOrder),
              ),
          ],
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 860;
              if (twoColumns) {
                final height = math.min(constraints.maxHeight, 760.0);
                return SizedBox(
                  height: height,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: _buildMain(),
                        ),
                      ),
                      const VerticalDivider(),
                      SizedBox(
                        width: 340,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: _buildSummary(),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _buildMain(),
                    const SizedBox(height: AppSpacing.lg),
                    SectionCard(
                      title: AppStrings.summaryTitle,
                      icon: Icons.calculate_outlined,
                      child: _buildSummary(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget? _buildErrorSummary() {
    if (_errors.isEmpty) return null;
    final more = _errors.length - 1;
    return Tooltip(
      message: _errors.join('\n'),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              more > 0
                  ? AppStrings.errorsMore(_errors.first, more)
                  : _errors.first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final totalMinutes = _plates.fold(0.0, (sum, p) => sum + p.minutes);
    final totalGrams = _plates.fold(0.0, (sum, p) => sum + p.grams);
    return PriceSummaryPanel(
      estimate: _estimate,
      attempts: _attempts,
      plateCount: _plates.length,
      totalMinutes: totalMinutes,
      totalGrams: totalGrams,
      priceController: _priceController,
      paidController: _paidController,
      isLocked: _isLocked,
      frozenCost: widget.initialOrder?.costOverride,
      onPriceChanged: _onFieldChanged,
      onPaidChanged: _onFieldChanged,
      onApplySuggested: () {
        _priceController.text = _estimate.suggestedPrice.toStringAsFixed(2);
        _onFieldChanged();
      },
      onSetPaid: (value) {
        _paidController.text = value.toStringAsFixed(2);
        _onFieldChanged();
      },
    );
  }

  Widget _buildMain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLocked) ...[
          _buildLockedBanner(),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildDataCard(),
        const SizedBox(height: AppSpacing.lg),
        PlatesSection(
          plates: _plates,
          materials: _materials,
          isLocked: _isLocked,
          onChanged: _recalculate,
          onAddPlate: _addPlate,
          onRemovePlate: _removePlate,
          onDuplicatePlate: _duplicatePlate,
          onAddNewMaterial: _addNewMaterial,
        ),
        const SizedBox(height: AppSpacing.lg),
        ExtrasSection(
          extras: _extras,
          unitPrices: _extraPrices,
          selected: _selectedExtras,
          isLocked: _isLocked,
          onQuantityChanged: _setExtraQuantity,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildProductionCard(),
      ],
    );
  }

  Widget _buildLockedBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: AppColors.info),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppStrings.lockedBanner,
              style: TextStyle(color: AppColors.info, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Estado del pedido en la cabecera: pastilla fija si está cerrado, o menú
  /// para cambiarlo.
  Widget _buildStatusHeader() {
    final pill = StatusPill(
      label: _status.label,
      color: statusColor(_status),
      icon: statusIcon(_status),
      trailing: _isLocked
          ? null
          : Icon(Icons.expand_more, size: 16, color: statusColor(_status)),
    );
    if (_isLocked) return pill;
    final options = {...OrderStatus.manualChoices, _status}.toList();
    return PopupMenuButton<OrderStatus>(
      tooltip: AppStrings.status,
      position: PopupMenuPosition.under,
      onSelected: (v) => setState(() {
        _status = v;
        _dirty = true;
      }),
      itemBuilder: (_) => [
        for (final s in options)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(statusIcon(s), size: 18, color: statusColor(s)),
                const SizedBox(width: 10),
                Text(s.label),
              ],
            ),
          ),
      ],
      child: pill,
    );
  }

  Widget _buildDataCard() {
    final clientField = Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            // La clave refleja el cliente recién creado desde aquí.
            key: ValueKey(_clientId),
            initialValue: _clientId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: AppStrings.clientOptional,
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text(AppStrings.unassigned),
              ),
              for (final c in _clients)
                DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _isLocked
                ? null
                : (v) => setState(() {
                    _clientId = v;
                    _dirty = true;
                  }),
          ),
        ),
        if (!_isLocked)
          IconButton(
            tooltip: AppStrings.createNewClient,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            color: AppColors.primary,
            onPressed: _addNewClient,
          ),
      ],
    );
    return SectionCard(
      title: AppStrings.orderDataTitle,
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          _ResponsiveRow(
            flexes: const [3, 2],
            children: [
              TextField(
                controller: _nameController,
                enabled: !_isLocked,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _onFieldChanged(),
                decoration: const InputDecoration(
                  labelText: AppStrings.projectName,
                ),
              ),
              clientField,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notesController,
            enabled: !_isLocked,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => _onFieldChanged(),
            decoration: const InputDecoration(
              labelText: AppStrings.notesLabel,
              prefixIcon: Icon(Icons.notes_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionCard() {
    return SectionCard(
      title: AppStrings.productionTitle,
      icon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResponsiveRow(
            children: [
              TextField(
                controller: _attemptsController,
                readOnly: _isLocked,
                keyboardType: decimalKeyboard,
                inputFormatters: decimalInputFormatters,
                onChanged: (_) => _recalculate(),
                decoration: const InputDecoration(
                  labelText: AppStrings.attemptsLabel,
                  helperText: AppStrings.attemptsHelp,
                  helperMaxLines: 2,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.paintServiceTitle),
                subtitle: const Text(
                  AppStrings.paintServiceHint,
                  style: AppTextStyles.mutedSmall,
                ),
                value: _isPainted,
                onChanged: _isLocked
                    ? null
                    : (v) {
                        _isPainted = v;
                        _recalculate();
                      },
              ),
            ],
          ),
          if (_isPainted) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              AppStrings.paintDetailLabel,
              style: AppTextStyles.mutedSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<PaintDetail>(
              showSelectedIcon: false,
              segments: [
                for (final d in PaintDetail.values)
                  ButtonSegment(
                    value: d,
                    label: Text(
                      '${_paintDetailName(d)} · '
                      '+${formatEuro(d.priceOf(_settings))}',
                    ),
                  ),
              ],
              selected: {_paintDetail},
              onSelectionChanged: _isLocked
                  ? null
                  : (v) {
                      _paintDetail = v.first;
                      _recalculate();
                    },
            ),
          ],
        ],
      ),
    );
  }
}

String _paintDetailName(PaintDetail d) => switch (d) {
  PaintDetail.simple => AppStrings.paintDetailSimple,
  PaintDetail.normal => AppStrings.paintDetailNormal,
  PaintDetail.detailed => AppStrings.paintDetailDetailed,
};

/// Coloca los hijos en una fila con la proporción [flexes] si caben, o
/// apilados si el ancho es pequeño. Nunca desborda.
class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.children, this.flexes});

  /// Por debajo de este ancho los hijos se apilan.
  static const double breakpoint = 460;

  final List<Widget> children;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                child,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(flex: flexes?[i] ?? 1, child: child),
            ],
          ],
        );
      },
    );
  }
}
