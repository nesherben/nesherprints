import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/number_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/strings.dart';
import '../../data/service_locator.dart';
// Extras management removed from admin panel - kept as separate screen

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  bool _isLoading = true;

  final _marginController = TextEditingController();
  final _paintHourController = TextEditingController();
  final _plateExtraController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Cargamos los valores de la base de datos a los cuadros de texto
  Future<void> _loadSettings() async {
    final data = await ServiceLocator.settingsRepo.getAllSettings();
    setState(() {
      _marginController.text =
          data[SettingKeys.margenBeneficio]?.toStringAsFixed(2) ?? '45.00';
      _paintHourController.text =
          data[SettingKeys.costeHoraPintado]?.toStringAsFixed(2) ?? '15.00';
      _plateExtraController.text =
          data[SettingKeys.costePlacaExtra]?.toStringAsFixed(2) ?? '2.50';
      _isLoading = false;
    });
  }

  // Guardamos los cambios en SQLite
  Future<void> _saveSettings() async {
    await ServiceLocator.settingsRepo.updateSetting(
      SettingKeys.margenBeneficio,
      parseDecimal(_marginController.text, fallback: 45.0),
    );
    await ServiceLocator.settingsRepo.updateSetting(
      SettingKeys.costeHoraPintado,
      parseDecimal(_paintHourController.text, fallback: 15.0),
    );
    await ServiceLocator.settingsRepo.updateSetting(
      SettingKeys.costePlacaExtra,
      parseDecimal(_plateExtraController.text, fallback: 2.50),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            AppStrings.settingsUpdated,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.statusCompletado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            UiStrings.admin,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width:
                600, // Limitamos el ancho para que parezca un panel de control
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculadora de Precios (Constantes)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'Estos valores afectarán automáticamente a los nuevos pedidos creados.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(height: 32),

                    _buildSettingRow(
                      'Margen de Beneficio (%)',
                      _marginController,
                      Icons.percent,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingRow(
                      'Coste de Pintado (€/hora)',
                      _paintHourController,
                      Icons.brush,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingRow(
                      'Extra por Placa Base (€)',
                      _plateExtraController,
                      Icons.layers,
                    ),

                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text(AppStrings.saveSettings),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                        ),
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

  Widget _buildSettingRow(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          flex: 1,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
