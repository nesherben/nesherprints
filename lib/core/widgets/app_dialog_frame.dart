import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';

/// Marco común de los diálogos: cabecera (icono, título, subtítulo y cierre),
/// contenido con scroll y pie con acciones.
///
/// El contenido nunca desborda: se adapta al alto de la ventana y se
/// desplaza si no cabe. [width] es el ancho deseado; en ventanas pequeñas
/// ocupa todo el ancho disponible.
class AppDialogFrame extends StatelessWidget {
  const AppDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primary,
    this.headerTrailing,
    this.actions = const [],
    this.footerLeading,
    this.width = 520,
    this.scrollable = true,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;

  /// Widget a la derecha del título (por ejemplo, una etiqueta de estado).
  final Widget? headerTrailing;
  final Widget child;

  /// Botones del pie, de izquierda a derecha (el último es el principal).
  final List<Widget> actions;

  /// Contenido a la izquierda del pie (por ejemplo, un mensaje de ayuda).
  final Widget? footerLeading;
  final double width;

  /// `false` si el contenido gestiona su propio scroll.
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(width, size.width - 32);
    final maxHeight = size.height - 48;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: dialogWidth,
          maxWidth: dialogWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: title,
              subtitle: subtitle,
              icon: icon,
              iconColor: iconColor,
              trailing: headerTrailing,
            ),
            const Divider(),
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(padding: padding, child: child)
                  : Padding(padding: padding, child: child),
            ),
            if (actions.isNotEmpty || footerLeading != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: _Footer(leading: footerLeading, actions: actions),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pie del diálogo: mensaje a la izquierda y botones a la derecha; si no
/// caben en una fila, el mensaje queda encima y los botones se reparten en
/// líneas (nunca desborda).
class _Footer extends StatelessWidget {
  const _Footer({required this.leading, required this.actions});

  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final buttons = Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(height: AppSpacing.md),
              ],
              buttons,
            ],
          );
        }
        return Row(
          children: [
            if (leading != null) Expanded(child: leading!) else const Spacer(),
            const SizedBox(width: AppSpacing.md),
            buttons,
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.mutedSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.maybePop(context),
          ),
        ],
      ),
    );
  }
}
