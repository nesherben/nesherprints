import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';

/// Chuleta de atajos de teclado (se abre con F1).
class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  static const _groups = <(String, List<(String, String)>)>[
    (
      AppStrings.shortcutsGlobal,
      [
        ('Ctrl + N', AppStrings.shortcutNewOrder),
        ('Ctrl + 1 … 6', AppStrings.shortcutGoTo),
        ('F1', AppStrings.shortcutHelp),
      ],
    ),
    (
      AppStrings.shortcutsOrders,
      [
        ('Ctrl + F', AppStrings.shortcutSearch),
        ('Ctrl + Mayús + N', AppStrings.shortcutQuickBar),
        ('↑  ↓', AppStrings.shortcutMoveRow),
        ('Intro', AppStrings.shortcutOpenRow),
      ],
    ),
    (
      AppStrings.shortcutsEditing,
      [
        ('Ctrl + S', AppStrings.shortcutSave),
        ('Intro', AppStrings.shortcutCellSave),
        ('Esc', AppStrings.shortcutCancel),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: AppStrings.shortcutsTitle,
      icon: Icons.keyboard_outlined,
      width: 520,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.close),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (title, rows) in _groups) ...[
            Text(title.toUpperCase(), style: AppTextStyles.overline),
            const SizedBox(height: AppSpacing.sm),
            for (final (keys, what) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 170,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        keys,
                        style: AppTextStyles.money.copyWith(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(what, style: AppTextStyles.muted)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
