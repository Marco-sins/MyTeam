import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class StartMatchUseCase {
  final IMatchRepository _matchRepository;

  StartMatchUseCase(this._matchRepository);

  Future<Either<Failure, void>> call(Match match, AuthUser user) async {
    final teamRole = user.teamRoles[match.teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure('You do not have permission to start this match.'),
      );
    }
    final startTime = DateTime.now();
    final startHour =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    Match updatedMatch = Match(
      id: match.id,
      teamId: match.teamId,
      opponent: match.opponent,
      goalsScored: match.goalsScored,
      goalsConceded: match.goalsConceded,
      date: startTime,
      hour: startHour,
      status: MatchStatus.firstHalf,
      lineups: match.lineups,
      isHome: match.isHome,
    );
    final response = await _matchRepository.updateMatch(updatedMatch);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
