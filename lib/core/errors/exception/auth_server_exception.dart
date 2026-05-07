/// Error específico de la capa de autenticación/servicio de identidad (Supabase
/// Auth). Se usa cuando la API de auth devuelve un error que debería tratarse
/// de forma diferenciada (p. ej. credenciales inválidas, token expirado).
class AuthServerException implements Exception {
  /// Mensaje descriptivo del error de autenticación.
  final String message;

  /// Código opcional devuelto por el proveedor de autenticación.
  final String? code;

  /// Crea una excepción de auth con mensaje y código opcional.
  AuthServerException(this.message, {this.code});

  @override
  String toString() => 'AuthServerException: message="$message", code="$code"';
}
