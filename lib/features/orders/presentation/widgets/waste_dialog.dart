import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/loading_dialog.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';

/// Registra una impresión fallida: placa, % impreso y motivo.
/// Los gramos perdidos se restan del inventario.
class WasteDialog extends StatefulWidget {
  const WasteDialog({super.key, required this.orderId, required this.onSaved});

  final int orderId;
  final VoidCallback onSaved;

  @override
  State<WasteDialog> createState() => _WasteDialogState();
}

class _WasteDialogState extends State<WasteDialog> {
  bool _isLoading = true;
  List<OrderPlate> _plates = [];
  OrderPlate? _selected;

  /// Porcentaje de la placa que llegó a imprimirse (y se pierde).
  double _percent = 100;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlates();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPlates() async {
    final plates = await ServiceLocator.orders.getPlates(widget.orderId);
    if (!mounted) return;
    setState(() {
      _plates = plates;
      _selected = plates.isNotEmpty ? plates.first : null;
      _isLoading = false;
    });
  }

  double get _wastedGrams =>
      _selected == null ? 0 : _selected!.grams * (_percent / 100);

  Future<void> _save() async {
    final plate = _selected;
    if (plate == null) return;
    final reason = _reasonController.text.trim().isEmpty
        ? AppStrings.defaultWasteReason(_percent, plate.name)
        : _reasonController.text;

    await ServiceLocator.orders.addWaste(
      orderId: widget.orderId,
      materialId: plate.materialId!,
      grams: _wastedGrams,
      reason: reason,
    );
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingDialog();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          SizedBox(width: 8),
          Text(AppStrings.wasteDialogTitle),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _plates.isEmpty
            ? const Text(
                AppStrings.orderHasNoPlates,
                style: AppTextStyles.muted,
              )
            : _buildForm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        if (_plates.isNotEmpty)
          ElevatedButton(
            style: AppButtonStyles.filled(AppColors.warning),
            onPressed: _save,
            child: const Text(AppStrings.registerWaste),
          ),
      ],
    );
  }

  Widget _buildForm() {
    const bold = TextStyle(fontWeight: FontWeight.bold);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(AppStrings.whichPlateFailed, style: bold),
        const SizedBox(height: 8),
        DropdownButtonFormField<OrderPlate>(
          initialValue: _selected,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final p in _plates)
              DropdownMenuItem(
                value: p,
                child: Text(AppStrings.plateOption(p.name, p.grams)),
              ),
          ],
          onChanged: (p) => setState(() => _selected = p),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.howMuchPrinted, style: bold),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                AppStrings.percent(_percent),
                style: const TextStyle(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _percent,
          max: 100,
          divisions: 20,
          activeColor: AppColors.warning,
          label: AppStrings.percent(_percent),
          onChanged: (v) => setState(() => _percent = v),
        ),
        Center(
          child: Text(
            AppStrings.gramsToDeduct(_wastedGrams),
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: AppStrings.wasteReasonLabel,
            hintText: AppStrings.wasteReasonHint,
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
