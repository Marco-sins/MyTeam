import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/i_repositories/i_match_repository.dart';

class UpdateMatchLineupPositionUseCase {
  final IMatchRepository _matchRepository;

  UpdateMatchLineupPositionUseCase(this._matchRepository);

  Future<Either<Failure, Unit>> call(int matchId, int playerId, int? position) {
    return _matchRepository.updateMatchLineupPosition(matchId, playerId, position);
  }
}
