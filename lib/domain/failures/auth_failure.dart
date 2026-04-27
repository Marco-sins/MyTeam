import 'package:football_manager/domain/failures/failure.dart';

class AuthFailure extends Failure {
  AuthFailure(super.message);

  @override
  String toString() => 'AuthFailure: $message';
}
