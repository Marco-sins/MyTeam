import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';

class DeleteMatchUseCase {
  final IMatchRepository _matchRepository;
  final IPlayerRepository _playerRepository;

  DeleteMatchUseCase(this._matchRepository, this._playerRepository);

  Future<Either<Failure, void>> call(Match match, AuthUser user) async {
    final teamRole = user.teamRoles[match.teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure('You do not have permission to delete this match.'),
      );
    }
    final response = await _matchRepository.deleteMatch(match.id);
    if (response.isLeft()) {
      return response;
    }
    // Las estadísticas agregadas en player_stats solo suman partidos
    // finalizados; borrar un pendiente o en curso no las altera.
    if (match.status != MatchStatus.finished) {
      return const Right(null);
    }
    final recalc = await _playerRepository.recalculateAllAggregatedStatsForTeam(
      match.teamId,
    );
    return recalc.map<void>((_) {});
  }
}
