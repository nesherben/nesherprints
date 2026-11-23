import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/constants/app_constants.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Administración: constantes de la calculadora de precios.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isLoading = true;

  /// Un controlador por ajuste, en el orden en que se muestran.
  late final Map<_Field, TextEditingController> _controllers = {
    for (final f in _Field.values) f: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Hasta 6 decimales sin ceros sobrantes: `50` → `50`, `0.0375` → `0.0375`.
  String _fmt(double v) =>
      v.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');

  Future<void> _load() async {
    final s = await ServiceLocator.settings.getPricingSettings();
    if (!mounted) return;
    setState(() {
      _controllers[_Field.profitMargin]!.text = _fmt(s.profitMarginPercent);
      _controllers[_Field.safetyMargin]!.text = _fmt(s.safetyMarginPercent);
      _controllers[_Field.paintingCost]!.text = _fmt(s.paintingCostPerHour);
      _controllers[_Field.paintDetailFew]!.text = _fmt(s.paintDetailFewCost);
      _controllers[_Field.paintDetailNormal]!.text = _fmt(
        s.paintDetailNormalCost,
      );
      _controllers[_Field.paintDetailMany]!.text = _fmt(s.paintDetailManyCost);
      _controllers[_Field.kwhCost]!.text = _fmt(s.kwhCost);
      _controllers[_Field.filamentFee]!.text = _fmt(s.filamentPlateFee);
      _controllers[_Field.resinFee]!.text = _fmt(s.resinPlateFee);
      _controllers[_Field.profitGoal]!.text = _fmt(s.profitGoal);
      _isLoading = false;
    });
  }

  double _value(_Field field, double fallback) =>
      parseDecimal(_controllers[field]!.text, fallback: fallback);

  Future<void> _save() async {
    await ServiceLocator.settings.savePricingSettings(
      PricingSettings(
        profitMarginPercent: _value(
          _Field.profitMargin,
          FinanceDefaults.profitMarginPercent,
        ),
        safetyMarginPercent: _value(
          _Field.safetyMargin,
          FinanceDefaults.safetyMarginPercent,
        ),
        paintingCostPerHour: _value(
          _Field.paintingCost,
          FinanceDefaults.paintingCostPerHour,
        ),
        paintDetailFewCost: _value(
          _Field.paintDetailFew,
          FinanceDefaults.paintDetailFewCost,
        ),
        paintDetailNormalCost: _value(
          _Field.paintDetailNormal,
          FinanceDefaults.paintDetailNormalCost,
        ),
        paintDetailManyCost: _value(
          _Field.paintDetailMany,
          FinanceDefaults.paintDetailManyCost,
        ),
        kwhCost: _value(_Field.kwhCost, FinanceDefaults.kwhCost),
        filamentPlateFee: _value(
          _Field.filamentFee,
          FinanceDefaults.filamentPlateFee,
        ),
        resinPlateFee: _value(_Field.resinFee, FinanceDefaults.resinPlateFee),
        profitGoal: _value(_Field.profitGoal, FinanceDefaults.profitGoal),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          AppStrings.settingsUpdated,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: AppStrings.settingsTitle),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 640,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.pricingCalculatorTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            AppStrings.pricingCalculatorHint,
                            style: AppTextStyles.mutedSmall,
                          ),
                          const Divider(height: 32),
                          for (final f in _Field.values) ...[
                            _SettingRow(
                              label: f.label,
                              hint: f.hint,
                              controller: _controllers[f]!,
                              icon: f.icon,
                            ),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _save,
                              icon: const Icon(Icons.save),
                              label: const Text(AppStrings.saveSettings),
                              style: AppButtonStyles.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ajustes editables, en el orden en que se muestran.
enum _Field {
  profitMargin(
    AppStrings.profitMarginLabel,
    Icons.percent,
    hint: AppStrings.profitMarginHint,
  ),
  safetyMargin(AppStrings.safetyMarginLabel, Icons.shield_outlined),
  kwhCost(AppStrings.kwhCostLabel, Icons.bolt),
  filamentFee(AppStrings.filamentPlateFeeLabel, Icons.layers),
  resinFee(AppStrings.resinPlateFeeLabel, Icons.layers),
  paintingCost(AppStrings.paintingCostLabel, Icons.brush),
  paintDetailFew(AppStrings.paintDetailFewCostLabel, Icons.palette_outlined),
  paintDetailNormal(
    AppStrings.paintDetailNormalCostLabel,
    Icons.palette_outlined,
  ),
  paintDetailMany(AppStrings.paintDetailManyCostLabel, Icons.palette_outlined),
  profitGoal(AppStrings.profitGoalLabel, Icons.flag_outlined);

  const _Field(this.label, this.icon, {this.hint});

  final String label;
  final IconData icon;
  final String? hint;
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              if (hint != null) Text(hint!, style: AppTextStyles.mutedSmall),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: decimalKeyboard,
            textAlign: TextAlign.end,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
