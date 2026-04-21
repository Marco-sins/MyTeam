import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';

/// Copia ficha de un jugador a otro equipo (mismo usuario admin en origen y destino).
/// Las estadísticas no se copian: se crea [PlayerStats] vacío en el nuevo jugador.
class ImportPlayerFromOtherTeamUseCase {
  final IPlayerRepository _playerRepository;

  ImportPlayerFromOtherTeamUseCase(this._playerRepository);

  Future<Either<Failure, Player>> call({
    required Player sourcePlayer,
    required int targetTeamId,
    required AuthUser user,
  }) async {
    if (sourcePlayer.teamId == targetTeamId) {
      return Left(
        PermissionFailure('That player already belongs to this team.'),
      );
    }
    final sourceRole = user.teamRoles[sourcePlayer.teamId];
    final targetRole = user.teamRoles[targetTeamId];
    if (sourceRole == null ||
        targetRole == null ||
        !sourceRole.hasAdminPrivileges ||
        !targetRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure(
          'You must be an admin on both the source team and this team.',
        ),
      );
    }

    final positions = sourcePlayer.positions;
    final imported = Player(
      id: 0,
      teamId: targetTeamId,
      firstName: sourcePlayer.firstName,
      lastName: sourcePlayer.lastName,
      number: sourcePlayer.number,
      phone: sourcePlayer.phone,
      email: sourcePlayer.email,
      imgUrl: sourcePlayer.imgUrl,
      positions: positions == null || positions.isEmpty
          ? null
          : List.of(positions),
      stats: null,
    );

    return _playerRepository.createPlayer(imported, const PlayerStats());
  }
}
