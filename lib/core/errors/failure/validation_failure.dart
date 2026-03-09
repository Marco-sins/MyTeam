import 'package:tfg1/core/errors/failure/failure.dart';

class ValidationFailure extends Failure {
  final String message;

  ValidationFailure(this.message);

  @override
  String toString() => 'ValidationFailure: $message';

}