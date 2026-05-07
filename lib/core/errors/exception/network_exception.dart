/// Indica un fallo de red (timeout, DNS, sin conexión). Se puede incluir un
/// [code] opcional con detalles de la capa de red.
class NetworkException implements Exception {
  /// Mensaje de error legible.
  final String message;

  /// Código opcional de la fuente que originó el fallo.
  final String? code;

  /// Construye la excepción de red.
  NetworkException(this.message, {this.code});

  @override
  String toString() => 'NetworkException: message="$message", code="$code"';
}
