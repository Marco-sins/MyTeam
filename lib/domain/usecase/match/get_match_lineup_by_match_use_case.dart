import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';
import 'package:football_manager/domain/i_repositories/i_match_repository.dart';

class GetMatchLineupByMatchUseCase {
  final IMatchRepository _matchRepository;

  GetMatchLineupByMatchUseCase(this._matchRepository);

  Future<Either<Failure, List<MatchLineup>>> call(int matchId) {
    return _matchRepository.getMatchLineupByMatchId(matchId);
  }
}
