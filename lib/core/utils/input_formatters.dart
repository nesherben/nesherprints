import 'package:flutter/services.dart';

/// Solo dígitos y un separador decimal (coma o punto).
final List<TextInputFormatter> decimalInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
];

/// Solo dígitos (cantidades enteras).
final List<TextInputFormatter> digitsOnlyFormatters = [
  FilteringTextInputFormatter.digitsOnly,
];

/// Teclado numérico con decimales.
const TextInputType decimalKeyboard = TextInputType.numberWithOptions(
  decimal: true,
);
