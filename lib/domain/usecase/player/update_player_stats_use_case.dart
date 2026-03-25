import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/player_stats.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class UpdatePlayerStatiticsUseCase {
  final IPlayerRepository _playerRepository;

  UpdatePlayerStatiticsUseCase(this._playerRepository);

  Future<Either<Failure, void>> call(
    PlayerStats playerStats,
    Player player,
    AuthUser user,
  ) async {
    if (user.teamRoles[player.teamId] != UserRole.admin) {
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
