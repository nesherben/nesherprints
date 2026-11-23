import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/number_utils.dart';
import 'package:nesherprints/core/strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';

class FinanceFormSection extends StatelessWidget {
  final TextEditingController platesController;
  final TextEditingController paintHoursController;
  final TextEditingController priceController;
  final TextEditingController paidController;
  final bool isPainted;
  final double suggestedPrice;
  final double totalCost;
  final double margenBeneficio;
  final bool isLocked;

  final Function(bool) onPaintedChanged;
  final Function(String) onPlatesChanged;
  final Function(String) onPaintHoursChanged;
  final Function(String) onPriceChanged;
  final Function(String) onPaidChanged;
  final VoidCallback onApplySuggestedPrice;

  const FinanceFormSection({
    super.key,
    required this.platesController,
    required this.paintHoursController,
    required this.priceController,
    required this.paidController,
    required this.isPainted,
    required this.suggestedPrice,
    required this.totalCost,
    required this.margenBeneficio,
    required this.isLocked,
    required this.onPaintedChanged,
    required this.onPlatesChanged,
    required this.onPaintHoursChanged,
    required this.onPriceChanged,
    required this.onPaidChanged,
    required this.onApplySuggestedPrice,
  });

  @override
  Widget build(BuildContext context) {
    Color getPriceColor(String currentPriceText) {
      // 1. Limpiamos por si escribes con coma
      String cleanText = currentPriceText.replaceAll(',', '.');
      double price = parseDecimal(cleanText);

      // Si no hay precio o coste, lo dejamos del color estándar
      if (price <= 0 || totalCost <= 0) return AppColors.primary;

      // --- TU LÓGICA DE NEGOCIO EXACTA ---

      // 1. Si es el precio sugerido o más -> VERDE
      if (price >= suggestedPrice) {
        return Colors.green;
      }

      // 2. Si está entre el gasto y el sugerido -> NARANJA
      if (price > totalCost && price < suggestedPrice) {
        return Colors.orange;
      }

      // 3. Si es el precio de coste o menos (pérdidas) -> ROJO
      return Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.financesTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 16),

        // --- FILA 1: Placas (Automáticas) y Pintura ---
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: platesController,
                decoration: const InputDecoration(
                  labelText: AppStrings.totalPlatesAuto,
                  border: OutlineInputBorder(),
                  filled: true,
                  // Color de fondo para indicar visualmente que no se puede editar
                  fillColor: AppColors.surface,
                  prefixIcon: Icon(Icons.layers, color: AppColors.textMuted),
                ),
                readOnly: true, // ¡BLOQUEO ACTIVADO!
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CheckboxListTile(
                title: const Text(AppStrings.paintServiceTitle),
                value: isPainted,
                onChanged: isLocked
                    ? null
                    : (v) => onPaintedChanged(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (isPainted) ...[
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: paintHoursController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.paintHoursLabel,
                    border: OutlineInputBorder(),
                    suffixText: 'h',
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: isLocked,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: onPaintHoursChanged,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // --- FILA 2: Precios y Pagos ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Alineamos todo arriba
            children: [
              // --- COLUMNA 1: DATOS INTERNOS (COSTE Y SUGERIDO) ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Coste Real (NUEVO)
                    const Text(
                      AppStrings.costManufacture,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '€${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey, // Discreto para que no abrume
                      ),
                    ),
                    const SizedBox(height: 12), // Separador
                    // 2. Precio Sugerido (LO QUE YA TENÍAS)
                    const Text(
                      AppStrings.suggestedPrice,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '€${suggestedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22, // Un pelín más grande para destacar
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (!isLocked)
                      TextButton.icon(
                        onPressed: onApplySuggestedPrice,
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                        ), // Cambiado a flecha lateral (opcional)
                        label: const Text(AppStrings.apply),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // --- COLUMNA 2: PRECIO FINAL ---
              Expanded(
                child: TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.finalPriceLabel,
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: getPriceColor(priceController.text),
                  ),
                  onChanged: onPriceChanged,
                  readOnly:
                      isLocked, // ¡Importante bloquearlo si está completado!
                ),
              ),
              const SizedBox(width: 16),

              // --- COLUMNA 3: PAGADO / ADELANTO ---
              Expanded(
                child: TextFormField(
                  controller: paidController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.paidAdvanceLabel,
                    border: OutlineInputBorder(),
                    prefixText: '€ ',
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: isLocked,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: onPaidChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
