/// Falhas tipadas que atravessam as camadas dentro de um [Result].
sealed class Failure {
  const Failure(this.message);

  /// Mensagem segura para exibir ao usuário (sem detalhes técnicos).
  final String message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.field});

  /// Nome do campo inválido, quando aplicável.
  final String? field;
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Registro não encontrado.']);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Não foi possível salvar. Tente novamente.']);
}

final class ImageFailure extends Failure {
  const ImageFailure([super.message = 'Não foi possível usar essa foto.']);
}
