import 'package:football_manager/domain/failures/failure.dart';

class PermissionFailure extends Failure {
  PermissionFailure(super.message);

  @override
  String toString() => 'PermissionFailure: $message';
}
