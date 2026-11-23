import 'package:flutter_test/flutter_test.dart';
import 'package:nesherprints/core/utils/number_utils.dart';

void main() {
  group('parseDecimal', () {
    test('acepta punto decimal', () {
      expect(parseDecimal('12.5'), 12.5);
    });

    test('acepta coma decimal', () {
      expect(parseDecimal('12,5'), 12.5);
    });

    test('ignora espacios alrededor', () {
      expect(parseDecimal('  3,25 '), 3.25);
    });

    test('devuelve el fallback con texto inválido, vacío o nulo', () {
      expect(parseDecimal('abc'), 0.0);
      expect(parseDecimal('', fallback: 2.5), 2.5);
      expect(parseDecimal(null, fallback: 7), 7);
    });
  });
}
