import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class RemovePositionToPlayerUseCase {
  final IPlayerRepository _playerRepository;

  RemovePositionToPlayerUseCase(this._playerRepository);

  Future<Either<Failure, void>> call(
    Player player,
    PlayerPosition position,
    AuthUser user,
  ) async {
    if (user.teamRoles[player.teamId] != UserRole.admin) {
      return Left(
        PermissionFailure(
          'You do not have permission to remove a position from this player.',
        ),
      );
    }
    List<PlayerPosition> updatedPositions = [];
    if (player.positions != null) {
      updatedPositions.addAll(player.positions!);
    }
    updatedPositions.remove(position);
    Player updatedPlayer = Player(
      id: player.id,
      teamId: player.teamId,
      firstName: player.firstName,
      lastName: player.lastName,
      number: player.number,
      phone: player.phone,
      email: player.email,
      positions: updatedPositions,
      stats: player.stats,
    );
    return await _playerRepository.updatePlayer(updatedPlayer);
  }
}
