import 'package:tfg1/core/errors/failure/failure.dart';

class ServerFailure extends Failure {
  ServerFailure(super.message);

  @override
  String toString() => 'ServerFailure: $message';
}