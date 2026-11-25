/// Texto para comparar al buscar: en minúsculas y sin tildes ni diéresis
/// («Dragón» y «dragon» coinciden). La ñ se conserva (es otra letra).
String foldText(String text) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüû';
  const to = 'aaaaaeeeeiiiiooooouuuu';
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    buffer.write(i < 0 ? ch : to[i]);
  }
  return buffer.toString();
}
