import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class FetchMatchLineupPositionsUseCase {
  FetchMatchLineupPositionsUseCase(this._repository);

  final IMatchRepository _repository;

  Future<Either<Failure, List<({int playerId, int positionIndex})>>> call(
    int matchId,
  ) =>
      _repository.getMatchLineupPositions(matchId);
}
