import 'package:flutter_test/flutter_test.dart';

/// Pulsa una acción de una fila por su texto: en pantalla ancha es un icono
/// con ese tooltip; en móvil, una opción del menú ⋮.
///
/// [index] elige la fila cuando hay varias (0 = la primera).
Future<void> tapRowMenu(WidgetTester t, String label, {int index = 0}) async {
  final more = find.byTooltip('Más acciones');
  if (more.evaluate().isEmpty) {
    await t.tap(find.byTooltip(label).at(index));
    await t.pumpAndSettle();
    return;
  }
  await t.tap(more.at(index));
  await t.pumpAndSettle();
  await t.tap(find.text(label).last);
  await t.pumpAndSettle();
}
