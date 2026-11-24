import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/clients/domain/client_stats.dart';

/// Tarjeta de cliente: avatar, contacto copiable y resumen de pedidos.
class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.client,
    required this.onEdit,
    this.stats = const ClientStats(),
  });

  /// Alto fijo de la tarjeta dentro de la rejilla.
  static const double height = 190;

  static const _avatarColors = [
    AppColors.primary,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.resinText,
    AppColors.filamentText,
    AppColors.dangerBright,
  ];

  final Client client;
  final ClientStats stats;
  final VoidCallback onEdit;

  /// Color del avatar derivado del nombre (siempre el mismo para un nombre).
  static Color avatarColorFor(String name) {
    final sum = name.codeUnits.fold<int>(0, (a, c) => a + c);
    return _avatarColors[sum % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = avatarColorFor(client.name);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    client.initials,
                    style: AppTextStyles.cardTitle.copyWith(color: color),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      Text(
                        AppStrings.clientStats(
                          stats.orderCount,
                          formatEuro(stats.billed),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.mutedSmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.info,
                  tooltip: AppStrings.editClient,
                  onPressed: onEdit,
                ),
              ],
            ),
            if (stats.owes) ...[
              const SizedBox(height: AppSpacing.sm),
              StatusPill(
                label: AppStrings.clientOwes(formatEuro(stats.pending)),
                color: AppColors.warning,
                icon: Icons.schedule,
              ),
            ],
            const Spacer(),
            if (client.phone.isNotEmpty)
              _ContactRow(
                icon: Icons.phone_outlined,
                text: client.phone,
                copyTooltip: AppStrings.copyPhone,
              ),
            if (client.email.isNotEmpty)
              _ContactRow(
                icon: Icons.alternate_email,
                text: client.email,
                copyTooltip: AppStrings.copyEmail,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.copyTooltip,
  });

  final IconData icon;
  final String text;
  final String copyTooltip;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    AppFeedback.success(context, AppStrings.copied);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.muted,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, size: 16),
          color: AppColors.textMuted,
          tooltip: copyTooltip,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          onPressed: () => _copy(context),
        ),
      ],
    );
  }
}
