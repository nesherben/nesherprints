import 'package:flutter/material.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/database/backup_service.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';

/// Lista las copias de seguridad y restaura la que se elija (previa
/// confirmación). Al terminar avisa de que hay que reiniciar la app.
class RestoreBackupDialog extends StatefulWidget {
  const RestoreBackupDialog({super.key});

  @override
  State<RestoreBackupDialog> createState() => _RestoreBackupDialogState();
}

class _RestoreBackupDialogState extends State<RestoreBackupDialog> {
  List<BackupInfo>? _backups;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ServiceLocator.backups.listBackups();
      if (!mounted) return;
      setState(() => _backups = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _backups = const []);
      AppFeedback.failure(context, e);
    }
  }

  static String _when(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  static String _size(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).round()} KB';

  Future<void> _restore(BackupInfo backup) async {
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.restoreConfirmTitle,
      message: AppStrings.restoreConfirmMessage(_when(backup.modified)),
      confirmText: AppStrings.restoreConfirm,
      color: AppColors.warning,
      icon: Icons.restore,
    );
    if (!ok || !mounted) return;
    try {
      await ServiceLocator.backups.restore(backup.path);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
      return;
    }
    if (!mounted) return;
    setState(() => _restored = true);
  }

  @override
  Widget build(BuildContext context) {
    final backups = _backups;
    return AppDialogFrame(
      title: AppStrings.restoreTitle,
      subtitle: _restored ? null : AppStrings.restoreSubtitle,
      icon: Icons.restore,
      iconColor: AppColors.warning,
      width: 560,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.close),
        ),
      ],
      child: _restored
          ? const Text(AppStrings.restoreDone, style: AppTextStyles.muted)
          : backups == null
          ? const Center(child: CircularProgressIndicator())
          : backups.isEmpty
          ? const Text(AppStrings.restoreNone, style: AppTextStyles.muted)
          : Column(
              children: [
                for (final b in backups)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.storage_outlined, size: 20),
                    title: Text(_when(b.modified)),
                    subtitle: Text(
                      '${b.name} · ${_size(b.bytes)}',
                      style: AppTextStyles.mutedSmall,
                    ),
                    trailing: TextButton(
                      onPressed: () => _restore(b),
                      child: const Text(AppStrings.restoreAction),
                    ),
                  ),
              ],
            ),
    );
  }
}
