import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class LockInitialLineupPositionsUseCase {
  LockInitialLineupPositionsUseCase(this._matchRepository);

  final IMatchRepository _matchRepository;

  Future<Either<Failure, Unit>> call(int matchId) {
    return _matchRepository.lockInitialLineupPositions(matchId);
  }
}
