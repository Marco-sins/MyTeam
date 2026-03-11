import 'package:tfg1/core/errors/failure/failure.dart';

class ValidationFailure extends Failure {
  ValidationFailure(super.message);

  @override
  String toString() => 'ValidationFailure: $message';

}