import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/empty_state.dart';
import 'package:nesherprints/features/dashboard/domain/finance_summary.dart';

/// Pedidos con importe pendiente de cobro, de mayor a menor deuda.
class PendingList extends StatelessWidget {
  const PendingList({super.key, required this.pending, required this.total});

  final List<PendingOrder> pending;
  final double total;

  /// Antigüedad en días de una fecha `YYYY-MM-DD` (`null` si no es válida).
  static int? ageInDays(String date, DateTime now) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return null;
    final days = now.difference(parsed).inDays;
    return days < 0 ? 0 : days;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.pendingListTitle,
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                if (pending.isNotEmpty)
                  Text(
                    formatEuro(total),
                    style: AppTextStyles.money.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: pending.isEmpty
                  ? const EmptyState(
                      icon: Icons.verified_outlined,
                      title: AppStrings.allCollected,
                    )
                  : ListView.separated(
                      // Sin el hueco de la barra de estado que añade por defecto.
                      padding: EdgeInsets.zero,
                      itemCount: pending.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (_, i) {
                        final order = pending[i];
                        final age = ageInDays(order.date, now);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      age == null
                                          ? AppStrings.orderNumber(order.id)
                                          : AppStrings.pendingAge(
                                              order.id,
                                              age,
                                            ),
                                      style: AppTextStyles.mutedSmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                formatEuro(order.amount),
                                style: AppTextStyles.money.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
