import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class PersistMatchLineupPositionsUseCase {
  PersistMatchLineupPositionsUseCase(this._repository);

  final IMatchRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int matchId,
    required List<int> convokedPlayerIds,
    required Map<int, int> onFieldPositionByPlayerId,
  }) =>
      _repository.persistMatchLineupPositions(
        matchId: matchId,
        convokedPlayerIds: convokedPlayerIds,
        onFieldPositionByPlayerId: onFieldPositionByPlayerId,
      );
}
