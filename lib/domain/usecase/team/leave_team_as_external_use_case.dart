import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

/// Abandono voluntario del equipo (elimina la fila en `team_members`).
/// Permitido para [UserRole.external], [UserRole.admin] y [UserRole.player].
/// El [UserRole.superAdmin] no puede usar esta vía (creador del equipo).
class LeaveTeamAsExternalUseCase {
  final ITeamRepository _teamRepository;

  LeaveTeamAsExternalUseCase(this._teamRepository);

  Future<Either<Failure, void>> call(int teamId, AuthUser user) async {
    final role = user.teamRoles[teamId];
    if (role == UserRole.superAdmin) {
      return Left(
        PermissionFailure(
          'El superadmin no puede abandonar el equipo desde aquí. '
          'Otro superadmin debe gestionar los accesos o eliminar el club.',
        ),
      );
    }
    if (role == null ||
        (role != UserRole.external &&
            role != UserRole.admin &&
            role != UserRole.player)) {
      return Left(
        PermissionFailure('No puedes abandonar este equipo.'),
      );
    }
    final response = await _teamRepository.removeSelfFromTeam(
      teamId: teamId,
      userId: user.id,
    );
    return response.map<void>((_) {});
  }
}
