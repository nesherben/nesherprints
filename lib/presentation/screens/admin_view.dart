import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/settings_repository.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final SettingsRepository _repo = SettingsRepository();
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
    final data = await _repo.getAllSettings();
    setState(() {
      _marginController.text =
          data['margen_beneficio']?.toStringAsFixed(2) ?? '45.00';
      _paintHourController.text =
          data['coste_hora_pintado']?.toStringAsFixed(2) ?? '15.00';
      _plateExtraController.text =
          data['coste_placa_extra']?.toStringAsFixed(2) ?? '2.50';
      _isLoading = false;
    });
  }

  // Guardamos los cambios en SQLite
  Future<void> _saveSettings() async {
    await _repo.updateSetting(
      'margen_beneficio',
      double.tryParse(_marginController.text) ?? 45.0,
    );
    await _repo.updateSetting(
      'coste_hora_pintado',
      double.tryParse(_paintHourController.text) ?? 15.0,
    );
    await _repo.updateSetting(
      'coste_placa_extra',
      double.tryParse(_plateExtraController.text) ?? 2.50,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Variables actualizadas correctamente',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.statusCompletado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Panel',
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

                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Configuración'),
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
