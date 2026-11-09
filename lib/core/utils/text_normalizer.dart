/// Normaliza texto para comparações: minúsculas, sem acentos e sem espaços extras.
///
/// Usado na busca por nome/região, porque o `LIKE` do SQLite só ignora
/// maiúsculas para ASCII (falharia em "São"/"sao").
abstract final class TextNormalizer {
  static const String _accented = 'áàâãäåéèêëíìîïóòôõöúùûüçñýÿ';
  static const String _plain = 'aaaaaaeeeeiiiiooooouuuucnyy';

  static final RegExp _whitespace = RegExp(r'\s+');

  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      // Ignora marcas de combinação (acentos em forma decomposta, NFD).
      if (rune >= 0x0300 && rune <= 0x036F) continue;
      final char = String.fromCharCode(rune);
      final index = _accented.indexOf(char);
      buffer.write(index == -1 ? char : _plain[index]);
    }
    return buffer.toString().trim().replaceAll(_whitespace, ' ');
  }
}
