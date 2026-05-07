import 'package:football_manager/core/errors/failure/failure.dart';

/// Falla que se produce cuando el usuario no tiene permisos para realizar
/// una acción (ej.: crear o modificar un evento de partido).
class PermissionFailure extends Failure {
  /// Construye la falla de permiso.
  PermissionFailure(super.message);

  @override
  String toString() => 'PermissionFailure: $message';
}
