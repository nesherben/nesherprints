import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';

/// Sección de piezas extra del formulario: contador −/+ por pieza.
class ExtrasSection extends StatelessWidget {
  const ExtrasSection({
    super.key,
    required this.extras,
    required this.selected,
    required this.isLocked,
    required this.onQuantityChanged,
  });

  final List<Extra> extras;

  /// Cantidad elegida por id de pieza (solo > 0).
  final Map<int, int> selected;
  final bool isLocked;
  final void Function(int extraId, int quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              AppStrings.extrasSectionTitle,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            if (extras.isEmpty) const Text(AppStrings.noExtrasDefined),
            for (final extra in extras) _buildRow(extra),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Extra extra) {
    final id = extra.id!;
    final qty = selected[id] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(extra.name)),
          Text(formatEuro(extra.unitPrice)),
          const SizedBox(width: 12),
          IconButton(
            onPressed: isLocked || qty <= 0
                ? null
                : () => onQuantityChanged(id, qty - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$qty'),
          IconButton(
            onPressed: isLocked ? null : () => onQuantityChanged(id, qty + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
