import 'package:football_manager/domain/failures/failure.dart';

class UnknowFailure extends Failure {
  UnknowFailure(super.message);

  @override
  String toString() => 'UnknowFailure: $message';
}
