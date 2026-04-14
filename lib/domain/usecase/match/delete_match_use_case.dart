import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/i_repositories/i_match_repository.dart';
import 'package:football_manager/domain/i_repositories/i_player_repository.dart';

class DeleteMatchUseCase {
  final IMatchRepository _matchRepository;
  final IPlayerRepository _playerRepository;

  DeleteMatchUseCase(this._matchRepository, this._playerRepository);

  Future<Either<Failure, void>> call(Match match, AuthUser user) async {
    if (user.teamRoles[match.teamId] != UserRole.admin) {
      return Left(
        PermissionFailure('You do not have permission to delete this match.'),
      );
    }
    final response = await _matchRepository.deleteMatch(match.id);
    if (response.isLeft()) {
      return response;
    }
    final recalc = await _playerRepository.recalculateAllAggregatedStatsForTeam(
      match.teamId,
    );
    return recalc.map<void>((_) {});
  }
}
