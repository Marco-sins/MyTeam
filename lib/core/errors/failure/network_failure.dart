import 'package:football_manager/core/errors/failure/failure.dart';

/// Falla derivada de problemas de red (timeouts, sin conexión, DNS).
class NetworkFailure extends Failure {
  /// Construye la falla de red con un mensaje legible.
  NetworkFailure(super.message);

  @override
  String toString() => 'NetworkFailure: $message';
}
