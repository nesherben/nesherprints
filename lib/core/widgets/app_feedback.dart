import 'package:flutter/material.dart';

import 'package:nesherprints/core/errors/app_exception.dart';
import 'package:nesherprints/core/theme/app_colors.dart';

/// Mensajes breves al usuario (barra inferior flotante) con estilo común.
class AppFeedback {
  AppFeedback._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_outline);

  /// Aviso con un botón «Deshacer» (borrados sin pedir confirmación).
  static void undo(BuildContext context, String message, VoidCallback onUndo) =>
      _show(
        context,
        message,
        AppColors.success,
        Icons.check_circle_outline,
        actionLabel: 'Deshacer',
        onAction: onUndo,
      );

  static void warning(BuildContext context, String message) =>
      _show(context, message, AppColors.warning, Icons.info_outline);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.danger, Icons.error_outline);

  /// Muestra el error de una operación fallida: el mensaje propio si es un
  /// [AppException]; uno genérico en otro caso.
  static void failure(BuildContext context, Object error) =>
      AppFeedback.error(context, describe(error));

  /// Texto para el usuario de un error.
  static String describe(Object error) => error is AppException
      ? error.message
      : 'No se pudo completar la operación. Inténtalo de nuevo.';

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 460,
          backgroundColor: AppColors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.6)),
          ),
          duration: onAction == null
              ? const Duration(seconds: 4)
              : const Duration(seconds: 8),
          action: onAction == null
              ? null
              : SnackBarAction(
                  label: actionLabel!,
                  textColor: AppColors.primary,
                  onPressed: onAction,
                ),
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
