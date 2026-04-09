import 'package:football_manager/core/errors/failure/failure.dart';

class AuthFailure extends Failure {
  AuthFailure(super.message);

  @override
  String toString() => 'AuthFailure: $message';
}
