import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';

/// Diálogo de confirmación. Devuelve `true` si el usuario confirma.
///
/// Con [color] el icono y el botón de confirmar usan ese color (rojo para
/// acciones destructivas).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  Color? color,
  String cancelText = AppStrings.cancel,
  IconData icon = Icons.help_outline,
}) async {
  final tint = color ?? AppColors.primary;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AppDialogFrame(
      title: title,
      icon: icon,
      iconColor: tint,
      width: 440,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: color == null ? null : AppButtonStyles.filled(color),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
      child: Text(message, style: AppTextStyles.body),
    ),
  );
  return confirmed ?? false;
}
