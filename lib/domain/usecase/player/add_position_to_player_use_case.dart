import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';

class AddPositionToPlayerUseCase {
  final IPlayerRepository _playerRepository;

  AddPositionToPlayerUseCase(this._playerRepository);

  Future<Either<Failure, void>> call(
    Player player,
    PlayerPosition position,
    AuthUser user,
  ) async {
    final teamRole = user.teamRoles[player.teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure(
          'You do not have permission to add a position to this player.',
        ),
      );
    }
    List<PlayerPosition> updatedPositions = [];
    if (player.positions != null) {
      updatedPositions.addAll(player.positions!);
    }
    updatedPositions = [position];
    Player updatedPlayer = Player(
      id: player.id,
      teamId: player.teamId,
      firstName: player.firstName,
      lastName: player.lastName,
      number: player.number,
      phone: player.phone,
      email: player.email,
      imgUrl: player.imgUrl,
      positions: updatedPositions,
      stats: player.stats,
    );
    final response = await _playerRepository.updatePlayer(updatedPlayer);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
