import 'package:football_manager/domain/failures/failure.dart';

class ServerFailure extends Failure {
  ServerFailure(super.message);

  @override
  String toString() => 'ServerFailure: $message';
}
