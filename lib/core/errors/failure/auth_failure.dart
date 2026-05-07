import 'package:football_manager/core/errors/failure/failure.dart';

/// Falla relacionada con operaciones de autenticación (login, registro,
/// refresh de sesión). Se usa para propagar mensajes manejables a la UI.
class AuthFailure extends Failure {
  /// Construye la falla de autenticación.
  AuthFailure(super.message);

  @override
  String toString() => 'AuthFailure: $message';
}
