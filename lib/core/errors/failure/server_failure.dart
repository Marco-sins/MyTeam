import 'package:football_manager/core/errors/failure/failure.dart';

/// Falla que representa un error del servidor/API. Se genera a partir de
/// [ServerException] y se utiliza para notificar a la capa superior.
class ServerFailure extends Failure {
  /// Construye la falla de servidor.
  ServerFailure(super.message);

  @override
  String toString() => 'ServerFailure: $message';
}
