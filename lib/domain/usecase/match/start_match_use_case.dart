import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/i_repositories/i_match_repository.dart';

class StartMatchUseCase {
  final IMatchRepository _matchRepository;

  StartMatchUseCase(this._matchRepository);

  Future<Either<Failure, void>> call(Match match, AuthUser user) async {
    if (user.teamRoles[match.teamId] != UserRole.admin) {
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
    );
    final response = await _matchRepository.updateMatch(updatedMatch);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
