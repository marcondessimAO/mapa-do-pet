import 'dart:developer' as developer;

/// Registro de erros técnicos. O usuário nunca vê esses detalhes (só `Failure.message`).
abstract final class AppLogger {
  static void error(String message, Object error, [StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'mapa_do_pet',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
