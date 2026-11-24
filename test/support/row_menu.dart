import 'package:flutter_test/flutter_test.dart';

/// Abre el menú ⋮ de una fila y pulsa una opción por su texto.
///
/// [index] elige la fila cuando hay varias (0 = la primera).
Future<void> tapRowMenu(WidgetTester t, String label, {int index = 0}) async {
  await t.tap(find.byTooltip('Más acciones').at(index));
  await t.pumpAndSettle();
  await t.tap(find.text(label).last);
  await t.pumpAndSettle();
}
