import 'package:football_manager/core/errors/failure/failure.dart';

class NetworkFailure extends Failure {
  NetworkFailure(super.message);

  @override
  String toString() => 'NetworkFailure: $message';
}
