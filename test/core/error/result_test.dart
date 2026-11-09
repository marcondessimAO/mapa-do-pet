import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_do_pet/core/error/failure.dart';
import 'package:mapa_do_pet/core/error/result.dart';

void main() {
  group('Result', () {
    test('Ok exposes its value', () {
      const Result<int> result = Ok(42);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 42);
    });

    test('Err exposes its failure and has no value', () {
      const Result<int> result =
          Err(ValidationFailure('inválido', field: 'name'));

      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(
          switch (result) {
            Err(:final failure) => failure.message,
            Ok() => 'não deveria chegar aqui',
          },
          'inválido');
    });

    test('default failure messages are user friendly', () {
      expect(const StorageFailure().message,
          'Não foi possível salvar. Tente novamente.');
      expect(const NotFoundFailure().message, 'Registro não encontrado.');
    });
  });
}
