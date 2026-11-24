import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
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
  bool _saving = false;
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
    try {
      final plates = await ServiceLocator.orders.getPlates(widget.orderId);
      if (!mounted) return;
      setState(() {
        _plates = plates;
        _selected = plates.isNotEmpty ? plates.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AppFeedback.failure(context, e);
    }
  }

  double get _wastedGrams =>
      _selected == null ? 0 : _selected!.grams * (_percent / 100);

  bool get _canSave => _selected != null && _wastedGrams > 0 && !_saving;

  Future<void> _save() async {
    final plate = _selected;
    if (plate == null || !_canSave) return;
    setState(() => _saving = true);
    final reason = _reasonController.text.trim().isEmpty
        ? AppStrings.defaultWasteReason(_percent, plate.name)
        : _reasonController.text.trim();
    try {
      await ServiceLocator.orders.addWaste(
        orderId: widget.orderId,
        materialId: plate.materialId!,
        grams: _wastedGrams,
        reason: reason,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.failure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingDialog();

    return AppDialogFrame(
      title: AppStrings.wasteDialogTitle,
      subtitle: AppStrings.wasteDialogSubtitle,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      width: 480,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        if (_plates.isNotEmpty)
          ElevatedButton.icon(
            style: AppButtonStyles.filled(AppColors.warning),
            onPressed: _canSave ? _save : null,
            icon: const Icon(Icons.recycling, size: 18),
            label: const Text(AppStrings.registerWaste),
          ),
      ],
      child: _plates.isEmpty
          ? const Text(AppStrings.orderHasNoPlates, style: AppTextStyles.muted)
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(AppStrings.whichPlateFailed, style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<OrderPlate>(
          initialValue: _selected,
          isExpanded: true,
          items: [
            for (final p in _plates)
              DropdownMenuItem(
                value: p,
                child: Text(
                  AppStrings.plateOption(p.name, p.grams),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (p) => setState(() => _selected = p),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            const Expanded(
              child: Text(
                AppStrings.howMuchPrinted,
                style: AppTextStyles.overline,
              ),
            ),
            Text(
              AppStrings.percent(_percent),
              style: AppTextStyles.money.copyWith(color: AppColors.warning),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _wastedGrams > 0
                      ? AppStrings.gramsToDeduct(_wastedGrams)
                      : AppStrings.nothingToDeduct,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: AppStrings.wasteReasonLabel,
            hintText: AppStrings.wasteReasonHint,
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
