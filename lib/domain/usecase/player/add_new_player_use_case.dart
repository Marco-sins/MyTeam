import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/i_repositories/i_player_repository.dart';

class AddNewPlayerUseCase {
  final IPlayerRepository _playerRepository;

  AddNewPlayerUseCase(this._playerRepository);

  Future<Either<Failure, Player>> call(Player player, AuthUser user) async {
    if (user.teamRoles[player.teamId] != UserRole.admin) {
      return Left(
        PermissionFailure('You do not have permission to add a new player.'),
      );
    }
    final PlayerStats initialStats = PlayerStats();
    return _playerRepository.createPlayer(player, initialStats);
  }
}
