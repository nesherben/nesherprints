import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/formatters.dart';
import 'package:nesherprints/core/utils/input_formatters.dart';
import 'package:nesherprints/core/utils/number_utils.dart';

/// Celda con un importe que se edita en el sitio: al tocarla se convierte en
/// un campo; Intro o salir del campo guarda, Esc cancela. [onSubmit] recibe el
/// nuevo valor y puede lanzar (el que llama avisa al usuario).
class InlineMoneyCell extends StatefulWidget {
  const InlineMoneyCell({
    super.key,
    required this.value,
    required this.display,
    required this.onSubmit,
    required this.tooltip,
    this.enabled = true,
    this.alignEnd = false,
  });

  final double value;

  /// Lo que se ve cuando no se edita.
  final Widget display;
  final Future<void> Function(double value) onSubmit;
  final String tooltip;
  final bool enabled;
  final bool alignEnd;

  @override
  State<InlineMoneyCell> createState() => _InlineMoneyCellState();
}

class _InlineMoneyCellState extends State<InlineMoneyCell> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _editing = false;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    _controller.text = formatFieldDecimal(widget.value);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    _done = false;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _cancel() {
    if (_done) return;
    _done = true;
    setState(() => _editing = false);
  }

  Future<void> _commit() async {
    if (_done) return;
    _done = true;
    final text = _controller.text.trim();
    final value = parseDecimal(text, fallback: widget.value);
    setState(() => _editing = false);
    if (text.isEmpty || (value - widget.value).abs() < 0.005) return;
    await widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.display;
    if (!_editing) {
      return Tooltip(
        message: widget.tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: _start,
          child: widget.display,
        ),
      );
    }
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _cancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: decimalKeyboard,
        inputFormatters: decimalInputFormatters,
        textAlign: widget.alignEnd ? TextAlign.end : TextAlign.start,
        style: AppTextStyles.money.copyWith(fontSize: 14),
        decoration: const InputDecoration(
          isDense: true,
          suffixText: '€',
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        onSubmitted: (_) => _commit(),
        onTapOutside: (_) => _commit(),
      ),
    );
  }
}
