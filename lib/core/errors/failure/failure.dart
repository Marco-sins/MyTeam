/// Convierte cualquier valor en texto seguro para mostrar o registrar.
/// Evita [NoSuchMethodError] u otros fallos al usar cadenas nulas o vacías.
String normalizeFailureMessage(Object? value) {
  if (value == null) return 'Error desconocido';
  try {
    final s = value.toString().trim();
    return s.isEmpty ? 'Error desconocido' : s;
  } catch (_) {
    return 'Error desconocido';
  }
}

abstract class Failure {
  final String message;

  Failure(Object? rawMessage) : message = normalizeFailureMessage(rawMessage);
}