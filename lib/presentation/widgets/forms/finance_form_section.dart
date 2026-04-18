import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FinanceFormSection extends StatelessWidget {
  // Datos de entrada
  final TextEditingController platesController;
  final TextEditingController paintHoursController;
  final TextEditingController priceController;
  final TextEditingController paidController;

  // Estados
  final bool isPainted;
  final double suggestedPrice;
  final bool isLocked;

  // Callbacks
  final Function(bool) onPaintedChanged;
  final Function(String) onPlatesChanged;
  final Function(String) onPaintHoursChanged;
  final Function(String) onPriceChanged;
  final Function(String) onPaidChanged;
  final Function() onApplySuggestedPrice;

  const FinanceFormSection({
    super.key,
    required this.platesController,
    required this.paintHoursController,
    required this.priceController,
    required this.paidController,
    required this.isPainted,
    required this.suggestedPrice,
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
    double price = double.tryParse(priceController.text) ?? 0.0;
    double paid = double.tryParse(paidController.text) ?? 0.0;
    double pending = price - paid;
    bool isUnderpriced = price < (suggestedPrice - 0.01) && price > 0;

    return Column(
      children: [
        // --- SECCIÓN 1: PLACAS Y PINTURA ---
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: platesController,
                decoration: const InputDecoration(
                  labelText: 'Nº Placas',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: !isLocked,
                onChanged: onPlatesChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CheckboxListTile(
                title: const Text("Pintado a mano"),
                value: isPainted,
                enabled: !isLocked,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => onPaintedChanged(v ?? false),
              ),
            ),
            if (isPainted)
              Expanded(
                child: TextField(
                  controller: paintHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Horas',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isLocked,
                  onChanged: onPaintHoursChanged,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // --- SECCIÓN 2: ANÁLISIS DE PRECIO ---
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Contabilidad del Pedido",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Sugerido: €${suggestedPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (!isLocked)
                        TextButton(
                          onPressed: onApplySuggestedPrice,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.only(left: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Copiar al Final",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isUnderpriced)
                    const Text(
                      "⚠️ Vendiendo por debajo del sugerido",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.alertBajoStock,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: pending > 0
                    ? AppColors.alertBajoStock.withOpacity(0.1)
                    : AppColors.statusCompletado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Pendiente: €${pending.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: pending > 0
                      ? AppColors.alertBajoStock
                      : AppColors.statusCompletado,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- SECCIÓN 3: ENTRADA DE PRECIOS ---
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: priceController,
                enabled: !isLocked,
                decoration: InputDecoration(
                  labelText: 'Precio Final (€)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.euro,
                    color: isUnderpriced
                        ? AppColors.alertBajoStock
                        : AppColors.primary,
                  ),
                ),
                style: TextStyle(
                  color: isUnderpriced
                      ? AppColors.alertBajoStock
                      : AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: onPriceChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: paidController,
                enabled: !isLocked,
                decoration: const InputDecoration(
                  labelText: 'Pagado / Adelanto (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.statusCompletado,
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.statusCompletado,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: onPaidChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
