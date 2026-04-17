import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class GetMatchesByTeamUseCase {
  final IMatchRepository _matchRepository;

  GetMatchesByTeamUseCase(this._matchRepository);

  Future<Either<Failure, List<Match>>> call(int teamId) {
    return _matchRepository.getMatchesByTeamId(teamId);
  }
}
