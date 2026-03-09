import 'package:tfg1/core/errors/failure/failure.dart';

class ServerFailure extends Failure {
  final String message;

  ServerFailure(this.message);

  @override
  String toString() => 'ServerFailure: $message';
}