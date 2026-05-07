import 'package:football_manager/core/errors/failure/failure.dart';

/// Representa una falla genérica que proviene de una excepción desconocida.
/// Se utiliza en la capa de repositorios para convertir excepciones a valores
/// del dominio (`Failure`) que la UI puede mostrar o registrar sin riesgo.
class UnknowFailure extends Failure {
  /// Crea una falla desconocida a partir de un mensaje.
  UnknowFailure(super.message);

  @override
  String toString() => 'UnknowFailure: $message';
}
