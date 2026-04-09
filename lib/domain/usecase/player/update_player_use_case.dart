import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/i_repositories/i_player_repository.dart';

class UpdatePlayerUseCase {
  final IPlayerRepository _playerRepository;

  UpdatePlayerUseCase(this._playerRepository);

  Future<Either<Failure, void>> call(Player player, AuthUser user) async {
    if (user.teamRoles[player.teamId] != UserRole.admin) {
      return Left(
        PermissionFailure('You do not have permission to update this player.'),
      );
    }
    final response = await _playerRepository.updatePlayer(player);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
