import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_colors.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/widgets/app_dialog_frame.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';

/// Selector de color RGB: tres deslizadores, código hexadecimal y los colores
/// de la biblioteca. Devuelve el RGB (0xRRGGBB) con `Navigator.pop`.
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, required this.initial, this.library});

  final int initial;
  final ColorLibrary? library;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late int _r = (widget.initial >> 16) & 0xFF;
  late int _g = (widget.initial >> 8) & 0xFF;
  late int _b = widget.initial & 0xFF;
  late final TextEditingController _hex = TextEditingController(
    text: _hexOf(widget.initial),
  );

  static String _hexOf(int rgb) =>
      rgb.toRadixString(16).padLeft(6, '0').toUpperCase();

  int get _rgb => (_r << 16) | (_g << 8) | _b;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(int rgb) {
    setState(() {
      _r = (rgb >> 16) & 0xFF;
      _g = (rgb >> 8) & 0xFF;
      _b = rgb & 0xFF;
      _hex.text = _hexOf(rgb);
    });
  }

  void _onHex(String text) {
    if (text.length != 6) return;
    final v = int.tryParse(text, radix: 16);
    if (v == null) return;
    setState(() {
      _r = (v >> 16) & 0xFF;
      _g = (v >> 8) & 0xFF;
      _b = v & 0xFF;
    });
  }

  Widget _slider(String label, int value, Color color, ValueChanged<int> on) {
    return Row(
      children: [
        SizedBox(width: 18, child: Text(label, style: AppTextStyles.muted)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(
              context,
            ).copyWith(activeTrackColor: color, thumbColor: color),
            child: Slider(
              min: 0,
              max: 255,
              value: value.toDouble(),
              onChanged: (v) {
                on(v.round());
                _hex.text = _hexOf(_rgb);
                setState(() {});
              },
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: AppTextStyles.muted,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = widget.library;
    return AppDialogFrame(
      title: AppStrings.pickColorTitle,
      icon: Icons.palette_outlined,
      width: 440,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _rgb),
          child: const Text(AppStrings.apply),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Color(0xFF000000 | _rgb),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextField(
                  controller: _hex,
                  maxLength: 6,
                  onChanged: _onHex,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: AppStrings.hexLabel,
                    prefixText: '# ',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _slider('R', _r, const Color(0xFFE5484D), (v) => _r = v),
          _slider('G', _g, const Color(0xFF22C55E), (v) => _g = v),
          _slider('B', _b, const Color(0xFF3B82F6), (v) => _b = v),
          if (library != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(AppStrings.libraryTitle, style: AppTextStyles.overline),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in library.entries.take(40))
                  Tooltip(
                    message: c.name,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _set(c.rgb),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(0xFF000000 | c.rgb),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
