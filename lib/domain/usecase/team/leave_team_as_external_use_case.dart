import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/i_repositories/i_team_repository.dart';

class LeaveTeamAsExternalUseCase {
  final ITeamRepository _teamRepository;

  LeaveTeamAsExternalUseCase(this._teamRepository);

  Future<Either<Failure, void>> call(int teamId, AuthUser user) async {
    if (user.teamRoles[teamId] != UserRole.external) {
      return Left(
        PermissionFailure(
          'Solo el rol externo puede abandonar el equipo de forma voluntaria.',
        ),
      );
    }
    final response = await _teamRepository.removeSelfFromTeam(
      teamId: teamId,
      userId: user.id,
    );
    return response.map<void>((_) {});
  }
}
