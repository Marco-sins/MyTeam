import 'package:football_manager/core/errors/failure/failure.dart';

class PermissionFailure extends Failure {
  PermissionFailure(super.message);

  @override
  String toString() => 'PermissionFailure: $message';
}
