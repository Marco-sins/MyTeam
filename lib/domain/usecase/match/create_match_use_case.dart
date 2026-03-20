import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/match_lineup.dart';
import 'package:tfg1/domain/i_repositories/i_match_repository.dart';

class CreateMatchUseCase {
  final IMatchRepository _matchRepository;

  CreateMatchUseCase(this._matchRepository);

  Future<Either<Failure, void>> call(Match match, AuthUser user) async {
    if (user.teamRoles[match.teamId] != UserRole.admin) {
      return Left(
        PermissionFailure('You do not have permission to create this match.'),
      );
    }
    Match newMatch = Match(
      id: match.id,
      teamId: match.teamId,
      opponent: match.opponent,
      goalsScored: 0,
      goalsConceded: 0,
      date: match.date,
      status: MatchStatus
          .notStarted, // Set status to notStarted to indicate the match is not yet started
      lineups: match.lineups, // Initialize lineups with the provided lineups
    );
    final result = await _matchRepository.createMatch(newMatch);
    if (result.isLeft()) {
      return result;
    }
    List<MatchLineup> lineups = newMatch.lineups;
    return await result.fold((failure) => Left(failure), (_) async {
      for (var lineup in lineups) {
        MatchLineup matchLineup = MatchLineup(
          id: lineup.id,
          playerId: lineup.playerId,
          matchId: newMatch.id,
          isStarting: lineup.isStarting,
          minutesPlayed: lineup.minutesPlayed,
          rating: lineup.rating,
        );
        final lineupResult = await _matchRepository.addMatchLineup(matchLineup);
        if (lineupResult.isLeft()) {
          return lineupResult;
        }
      }
      return const Right(null);
    });
  }
}
