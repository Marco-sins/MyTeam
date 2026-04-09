import 'package:football_manager/core/errors/failure/failure.dart';

class UnknowFailure extends Failure {
  UnknowFailure(super.message);

  @override
  String toString() => 'UnknowFailure: $message';
}
