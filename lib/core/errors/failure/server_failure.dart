import 'package:football_manager/core/errors/failure/failure.dart';

class ServerFailure extends Failure {
  ServerFailure(super.message);

  @override
  String toString() => 'ServerFailure: $message';
}