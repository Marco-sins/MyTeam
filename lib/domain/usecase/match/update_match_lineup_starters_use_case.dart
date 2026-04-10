import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/i_repositories/i_match_repository.dart';

class UpdateMatchLineupStartersUseCase {
  final IMatchRepository _matchRepository;

  UpdateMatchLineupStartersUseCase(this._matchRepository);

  Future<Either<Failure, Unit>> call(int matchId, List<int> starterIds) async {
    final clearResult = await _matchRepository.clearMatchLineupStarters(matchId);
    if (clearResult.isLeft()) {
      return clearResult;
    }

    for (final playerId in starterIds) {
      final setResult = await _matchRepository.setMatchLineupStarter(
        matchId,
        playerId,
        true,
      );
      if (setResult.isLeft()) {
        return setResult;
      }
    }

    return const Right(unit);
  }
}
