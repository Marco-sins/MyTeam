import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class ApplyMatchSecondHalfStartedUseCase {
  ApplyMatchSecondHalfStartedUseCase(this._repository);

  final IMatchRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int matchId,
    required DateTime secondHalfStart,
  }) =>
      _repository.updateMatchStatusSecondHalf(
        matchId: matchId,
        secondHalfStart: secondHalfStart,
      );
}
