import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer.normalize', () {
    test('lowercases the text', () {
      expect(TextNormalizer.normalize('PRAÇA Central'), 'praca central');
    });

    test('removes Portuguese diacritics', () {
      expect(TextNormalizer.normalize('São Paulo'), 'sao paulo');
      expect(TextNormalizer.normalize('AÇÃO'), 'acao');
      expect(TextNormalizer.normalize('órfão ênfase'), 'orfao enfase');
    });

    test('trims and collapses whitespace', () {
      expect(
          TextNormalizer.normalize('  rua   das  flores '), 'rua das flores');
    });

    test('returns an empty string for blank input', () {
      expect(TextNormalizer.normalize(''), '');
      expect(TextNormalizer.normalize('   '), '');
    });
  });
}
