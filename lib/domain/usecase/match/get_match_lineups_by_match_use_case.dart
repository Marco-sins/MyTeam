import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class GetMatchLineupsByMatchUseCase {
  GetMatchLineupsByMatchUseCase(this._matchRepository);

  final IMatchRepository _matchRepository;

  Future<Either<Failure, List<MatchLineup>>> call(int matchId) {
    return _matchRepository.getMatchLineupsByMatchId(matchId);
  }
}
