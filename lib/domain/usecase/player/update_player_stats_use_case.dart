import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';

class UpdatePlayerStatiticsUseCase {
  final IPlayerRepository _playerRepository;

  UpdatePlayerStatiticsUseCase(this._playerRepository);

  Future<Either<Failure, void>> call(
    PlayerStats playerStats,
    Player player,
    AuthUser user,
  ) async {
    final teamRole = user.teamRoles[player.teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure(
          'You do not have permission to update the statistics of this player.',
        ),
      );
    }
    final response = await _playerRepository.updatePlayerStats(player.id, playerStats);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
