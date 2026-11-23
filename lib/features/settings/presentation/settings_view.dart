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
  final _marginController = TextEditingController();
  final _paintingController = TextEditingController();
  final _plateExtraController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _marginController.dispose();
    _paintingController.dispose();
    _plateExtraController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await ServiceLocator.settings.getPricingSettings();
    if (!mounted) return;
    setState(() {
      _marginController.text = s.profitMarginPercent.toStringAsFixed(2);
      _paintingController.text = s.paintingCostPerHour.toStringAsFixed(2);
      _plateExtraController.text = s.plateExtraCost.toStringAsFixed(2);
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    await ServiceLocator.settings.savePricingSettings(
      PricingSettings(
        profitMarginPercent: parseDecimal(
          _marginController.text,
          fallback: FinanceDefaults.profitMarginPercent,
        ),
        paintingCostPerHour: parseDecimal(
          _paintingController.text,
          fallback: FinanceDefaults.paintingCostPerHour,
        ),
        plateExtraCost: parseDecimal(
          _plateExtraController.text,
          fallback: FinanceDefaults.plateExtraCost,
        ),
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
          SizedBox(
            width: 600,
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
                    _SettingRow(
                      label: AppStrings.profitMarginLabel,
                      controller: _marginController,
                      icon: Icons.percent,
                    ),
                    const SizedBox(height: 16),
                    _SettingRow(
                      label: AppStrings.paintingCostLabel,
                      controller: _paintingController,
                      icon: Icons.brush,
                    ),
                    const SizedBox(height: 16),
                    _SettingRow(
                      label: AppStrings.plateExtraCostLabel,
                      controller: _plateExtraController,
                      icon: Icons.layers,
                    ),
                    const SizedBox(height: 24),
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
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.controller,
    required this.icon,
  });

  final String label;
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
          child: Text(label, style: const TextStyle(fontSize: 16)),
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
