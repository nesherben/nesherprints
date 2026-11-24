import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/row_actions.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/clients/domain/client_stats.dart';

/// Tarjeta de cliente con siempre la misma estructura: cabecera (avatar,
/// nombre, nº de pedidos y acciones), dos líneas de contacto (con un hueco
/// marcado si falta el dato) y un pie con lo facturado y lo pendiente.
class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.client,
    required this.onEdit,
    this.onDelete,
    this.stats = const ClientStats(),
  });

  /// Alto de la tarjeta en rejilla.
  static const double height = 200;

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
  final VoidCallback? onDelete;

  /// Color del avatar derivado del nombre (siempre el mismo para un nombre).
  static Color avatarColorFor(String name) {
    final sum = name.codeUnits.fold<int>(0, (a, c) => a + c);
    return _avatarColors[sum % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = avatarColorFor(client.name);
    // Alto fijo también en lista: así todas las tarjetas miden lo mismo.
    return SizedBox(
      height: height,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
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
                            AppStrings.clientOrders(stats.orderCount),
                            style: AppTextStyles.mutedSmall,
                          ),
                        ],
                      ),
                    ),
                    RowActions(
                      items: [
                        RowMenuItem(
                          icon: Icons.edit_outlined,
                          label: AppStrings.editClient,
                          onTap: onEdit,
                        ),
                        if (onDelete != null)
                          RowMenuItem(
                            icon: Icons.delete_outline,
                            label: AppStrings.deleteClient,
                            onTap: onDelete!,
                            danger: true,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _ContactLine(
                  icon: Icons.phone_outlined,
                  value: client.phone,
                  emptyText: AppStrings.noPhone,
                  copyTooltip: AppStrings.copyPhone,
                ),
                _ContactLine(
                  icon: Icons.alternate_email,
                  value: client.email,
                  emptyText: AppStrings.noEmail,
                  copyTooltip: AppStrings.copyEmail,
                ),
                const Spacer(),
                const Divider(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Figure(
                          label: AppStrings.clientBilled,
                          value: formatEuro(stats.billed),
                        ),
                      ),
                      Expanded(
                        child: _Figure(
                          label: AppStrings.clientPending,
                          value: stats.owes
                              ? formatEuro(stats.pending)
                              : AppStrings.clientUpToDate,
                          color: stats.owes
                              ? AppColors.warning
                              : AppColors.success,
                          icon: stats.owes
                              ? Icons.schedule
                              : Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cifra con su etiqueta encima.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.color = AppColors.textMain,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.overline),
        const SizedBox(height: 2),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(color: color),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Línea de contacto de alto fijo: el dato con su botón de copiar, o un
/// texto atenuado si no hay.
class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.value,
    required this.emptyText,
    required this.copyTooltip,
  });

  static const double height = 30;

  final IconData icon;
  final String value;
  final String emptyText;
  final String copyTooltip;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    AppFeedback.success(context, AppStrings.copied);
  }

  @override
  Widget build(BuildContext context) {
    final has = value.isNotEmpty;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: has ? AppColors.textMuted : AppColors.border,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              has ? value : emptyText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: has
                  ? AppTextStyles.muted.copyWith(color: AppColors.textMain)
                  : AppTextStyles.mutedSmall.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
            ),
          ),
          if (has)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 16),
              color: AppColors.textMuted,
              tooltip: copyTooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 30),
              onPressed: () => _copy(context),
            ),
        ],
      ),
    );
  }
}
