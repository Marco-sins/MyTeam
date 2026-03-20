import 'package:tfg1/core/errors/failure/failure.dart';

class PermissionFailure extends Failure {
  PermissionFailure(super.message);

  @override
  String toString() => 'PermissionFailure: $message';
}
