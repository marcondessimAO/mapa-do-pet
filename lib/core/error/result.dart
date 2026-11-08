import 'failure.dart';

/// Resultado de uma operação: sucesso ([Ok]) ou falha ([Err]).
///
/// Exceções não atravessam camadas; a camada de dados as converte em [Err].
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
