import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/i_repositories/i_team_repository.dart';

class DeleteTeamUseCase {
  final ITeamRepository _teamRepository;

  DeleteTeamUseCase(this._teamRepository);

  Future<Either<Failure, void>> call(Team team, AuthUser user) async {
    final teamRole = user.teamRoles[team.id];
    if (teamRole != UserRole.superAdmin) {
      return Left(
        PermissionFailure(
          'Solo el superadmin del equipo puede borrarlo.',
        ),
      );
    }
    final response = await _teamRepository.deleteTeam(team.id);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
