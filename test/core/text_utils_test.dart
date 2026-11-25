import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/core/utils/text_utils.dart';

void main() {
  test('foldText quita tildes y pasa a minúsculas', () {
    expect(foldText('Dragón ROJO'), 'dragon rojo');
    expect(foldText('PÜNTO ÉÍÓÚ'), 'punto eiou');
  });

  test('foldText conserva la ñ y otros caracteres', () {
    expect(foldText('Niño #7'), 'niño #7');
  });
}
