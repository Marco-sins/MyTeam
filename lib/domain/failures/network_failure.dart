import 'package:football_manager/domain/failures/failure.dart';

class NetworkFailure extends Failure {
  NetworkFailure(super.message);

  @override
  String toString() => 'NetworkFailure: $message';
}
