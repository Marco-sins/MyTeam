import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/i_repositories/i_match_repository.dart';

class GetMatchesByTeamUseCase {
  final IMatchRepository _matchRepository;

  GetMatchesByTeamUseCase(this._matchRepository);

  Future<Either<Failure, List<Match>>> call(int teamId) {
    return _matchRepository.getMatchesByTeamId(teamId);
  }
}
