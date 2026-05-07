/// Representa un error devuelto por el servidor o por la capa de API (PostgREST,
/// Supabase). Incluye un [message] y un [code] opcional con el código del error
/// proporcionado por el backend.
class ServerException implements Exception {
  /// Mensaje descriptivo del error proporcionado por el servidor.
  final String message;

  /// Código opcional retornado por la API (p. ej. "PGRST-123").
  final String? code;

  /// Crea una excepción de servidor con mensaje y código opcional.
  ServerException({required this.message, this.code});

  @override
  String toString() => 'ServerException: message="$message", code="$code"';
}
