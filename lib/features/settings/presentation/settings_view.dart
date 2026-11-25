import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/app/service_locator.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/open_folder.dart';
import 'package:nesherprints/core/utils/responsive.dart';
import 'package:nesherprints/core/widgets/app_feedback.dart';
import 'package:nesherprints/core/widgets/confirm_dialog.dart';
import 'package:nesherprints/core/widgets/page_header.dart';
import 'package:nesherprints/core/widgets/section_card.dart';
import 'package:nesherprints/core/widgets/status_pill.dart';
import 'package:nesherprints/features/orders/domain/pricing_calculator.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';
import 'package:nesherprints/features/settings/presentation/settings_fields.dart';
import 'package:nesherprints/features/settings/presentation/widgets/restore_backup_dialog.dart';

/// Administración: constantes de la calculadora de precios.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  /// Ancho a partir del cual las tarjetas van en dos columnas.
  static const double _twoColumnsWidth = 960;

  bool _isLoading = true;
  bool _isSaving = false;

  /// Lo último guardado; sirve para saber si hay cambios.
  PricingSettings _saved = const PricingSettings();

  late final Map<SettingField, TextEditingController> _controllers = {
    for (final f in SettingField.values) f: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    for (final c in _controllers.values) {
      c.addListener(_onTextChanged);
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c
        ..removeListener(_onTextChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _fill(PricingSettings s) {
    for (final f in SettingField.values) {
      _controllers[f]!.text = formatSettingValue(f.valueOf(s));
    }
  }

  Future<void> _load() async {
    try {
      final s = await ServiceLocator.settings.getPricingSettings();
      if (!mounted) return;
      setState(() {
        _saved = s;
        _fill(s);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.failure(context, e);
    }
  }

  /// Valor numérico del campo, o `null` si el texto no es válido.
  double? _parsed(SettingField f) => f.parse(_controllers[f]!.text);

  String? _error(SettingField f) => f.validate(_controllers[f]!.text);

  bool get _isValid => SettingField.values.every((f) => _error(f) == null);

  bool get _isDirty => SettingField.values.any((f) {
    return !SettingField.sameValue(_parsed(f), f.valueOf(_saved));
  });

  /// Valor del campo; si coincide con lo guardado o con el de fábrica se usa
  /// el exacto (el texto solo muestra 6 decimales).
  double _resolved(SettingField f) {
    final v = _parsed(f)!;
    if (SettingField.sameValue(v, f.valueOf(_saved))) return f.valueOf(_saved);
    if (SettingField.sameValue(v, f.defaultValue)) return f.defaultValue;
    return v;
  }

  /// Ajustes con lo escrito ahora; `null` si algún campo no es válido.
  PricingSettings? _current() {
    if (!_isValid) return null;
    return PricingSettings.fromMap({
      for (final f in SettingField.values) f.key: _resolved(f),
    });
  }

  bool get _canSave => !_isSaving && _isDirty && _isValid;

  Future<void> _save() async {
    final settings = _current();
    if (!_canSave || settings == null) return;
    setState(() => _isSaving = true);
    try {
      await ServiceLocator.settings.savePricingSettings(settings);
      if (!mounted) return;
      setState(() {
        _saved = settings;
        _isSaving = false;
      });
      AppFeedback.success(context, AppStrings.settingsUpdated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppFeedback.failure(context, e);
    }
  }

  Future<void> _restoreAll() async {
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.settingsRestoreAllTitle,
      message: AppStrings.settingsRestoreAllMessage,
      confirmText: AppStrings.settingsRestoreAllConfirm,
      icon: Icons.restore,
    );
    if (!ok || !mounted) return;
    _fill(const PricingSettings());
  }

  void _restoreOne(SettingField f) {
    _controllers[f]!.text = formatSettingValue(f.defaultValue);
  }

  Widget _group(SettingGroup group) => SectionCard(
    title: group.title,
    subtitle: group.subtitle,
    icon: group.icon,
    child: Column(
      children: [
        for (final (i, f) in group.fields.indexed) ...[
          if (i > 0) const Divider(height: AppSpacing.lg + AppSpacing.sm),
          _SettingRow(
            field: f,
            controller: _controllers[f]!,
            error: _error(f),
            onRestore: () => _restoreOne(f),
          ),
        ],
      ],
    ),
  );

  Widget _example() => _LiveExample(settings: _current());

  Future<void> _backupNow() async {
    try {
      final path = await ServiceLocator.backups.backupNow();
      if (!mounted) return;
      AppFeedback.success(context, AppStrings.backupDone(path));
    } catch (e) {
      if (!mounted) return;
      AppFeedback.failure(context, e);
    }
  }

  Future<void> _openBackups() async {
    final folder = await ServiceLocator.backups.backupsFolder();
    await openFolder(folder);
  }

  Widget _backupCard() => SectionCard(
    title: AppStrings.backupTitle,
    icon: Icons.shield_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(AppStrings.backupHint, style: AppTextStyles.muted),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ElevatedButton.icon(
              onPressed: _backupNow,
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text(AppStrings.backupNow),
            ),
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const RestoreBackupDialog(),
              ),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text(AppStrings.restoreButton),
            ),
            if (canOpenFolders)
              OutlinedButton.icon(
                onPressed: _openBackups,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text(AppStrings.openFolder),
              ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final dirty = _isDirty;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: EdgeInsets.all(context.isCompact ? AppSpacing.lg : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: AppStrings.settingsTitle,
                subtitle: AppStrings.settingsSubtitle,
                actions: [
                  StatusPill(
                    label: dirty
                        ? AppStrings.settingsUnsaved
                        : AppStrings.settingsSaved,
                    color: dirty ? AppColors.warning : AppColors.success,
                    icon: dirty ? Icons.edit_note : Icons.check,
                  ),
                  OutlinedButton.icon(
                    onPressed: _restoreAll,
                    icon: const Icon(Icons.restore),
                    label: const Text(AppStrings.settingsRestoreAll),
                  ),
                  ElevatedButton.icon(
                    onPressed: _canSave ? _save : null,
                    icon: const Icon(Icons.save),
                    label: const Text(AppStrings.saveSettings),
                    style: AppButtonStyles.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      if (c.maxWidth < _twoColumnsWidth) {
                        return Column(
                          children: [
                            for (final g in SettingGroup.values) ...[
                              _group(g),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            _example(),
                            const SizedBox(height: AppSpacing.md),
                            _backupCard(),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _group(SettingGroup.price),
                                const SizedBox(height: AppSpacing.md),
                                _group(SettingGroup.production),
                                const SizedBox(height: AppSpacing.md),
                                _group(SettingGroup.goals),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              children: [
                                _example(),
                                const SizedBox(height: AppSpacing.md),
                                _group(SettingGroup.paint),
                                const SizedBox(height: AppSpacing.md),
                                _backupCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una fila: etiqueta, ayuda, valor por defecto y campo con sufijo.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.field,
    required this.controller,
    required this.error,
    required this.onRestore,
  });

  final SettingField field;
  final TextEditingController controller;
  final String? error;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final parsed = field.parse(controller.text);
    final differs = !SettingField.sameValue(parsed, field.defaultValue);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: AppTextStyles.cardTitle),
        const SizedBox(height: 2),
        Text(
          '${field.hint} · ${AppStrings.settingsDefaultValue('${formatSettingValue(field.defaultValue)} ${field.suffix}')}',
          style: AppTextStyles.mutedSmall,
        ),
      ],
    );

    final input = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: TextField(
            key: ValueKey(field.key),
            controller: controller,
            keyboardType: decimalKeyboard,
            inputFormatters: decimalInputFormatters,
            textAlign: TextAlign.end,
            decoration: InputDecoration(
              isDense: true,
              suffixText: field.suffix,
              errorText: error,
              errorMaxLines: 2,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: differs
              ? IconButton(
                  tooltip: AppStrings.settingsRestoreOne,
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore, size: 18),
                )
              : null,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              info,
              const SizedBox(height: AppSpacing.sm),
              input,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: info),
            const SizedBox(width: AppSpacing.md),
            input,
          ],
        );
      },
    );
  }
}

/// Pedido de muestra calculado con los valores que hay ahora en los campos.
class _LiveExample extends StatelessWidget {
  const _LiveExample({required this.settings});

  /// `null` si algún campo no es válido.
  final PricingSettings? settings;

  static const _materialId = 1;

  PriceEstimate? _estimate() {
    final s = settings;
    if (s == null) return null;
    return PricingCalculator.estimate(
      plates: const [
        PricingPlate(materialId: _materialId, grams: 100, minutes: 480),
      ],
      materialCostPerKg: const {_materialId: 20},
      extraUnitPrices: const {},
      selectedExtras: const {},
      attempts: 1,
      paintDetail: null,
      settings: s,
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = _estimate();
    return SectionCard(
      title: AppStrings.settingsExampleTitle,
      subtitle: AppStrings.settingsExampleHint,
      icon: Icons.calculate_outlined,
      child: e == null
          ? const Text(
              AppStrings.settingsExampleInvalid,
              style: AppTextStyles.muted,
            )
          : Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.md,
              children: [
                _Figure(
                  label: AppStrings.settingsExampleCost,
                  value: formatEuro(e.cost),
                ),
                _Figure(
                  label: AppStrings.settingsExamplePrice,
                  value: formatEuro(e.suggestedPrice),
                  highlight: true,
                ),
              ],
            ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.overline),
        const SizedBox(height: 2),
        Text(
          value,
          style: highlight
              ? AppTextStyles.kpiValue.copyWith(color: AppColors.primary)
              : AppTextStyles.kpiValue,
        ),
      ],
    );
  }
}
