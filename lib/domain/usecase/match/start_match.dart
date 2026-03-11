import 'package:dartz/dartz.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/i_repositories/i_match_repository.dart';

class StartMatch {
  final IMatchRepository _matchRepository;

  StartMatch(this._matchRepository);

  Future<Either<Failure, void>> call(Match match) async {
    Match updatedMatch = Match(
      id: match.id,
      teamId: match.teamId,
      opponent: match.opponent,
      goalsScored: match.goalsScored,
      goalsConceded: match.goalsConceded,
      date: match.date,
      status: MatchStatus.inProgress, 
      lineups: match.lineups,
    );
    return await _matchRepository.updateMatch(updatedMatch);
  }
}