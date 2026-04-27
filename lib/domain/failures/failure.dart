/// Convierte cualquier valor en texto seguro para mostrar o registrar.
String normalizeFailureMessage(Object? value) {
  if (value == null) return 'Error desconocido';
  try {
    final s = value.toString().trim();
    return s.isEmpty ? 'Error desconocido' : s;
  } catch (_) {
    return 'Error desconocido';
  }
}

/// Error de negocio o de capa externa mapeado al dominio (resultado [Either.left]).
abstract class Failure {
  final String message;

  Failure(Object? rawMessage) : message = normalizeFailureMessage(rawMessage);
}
