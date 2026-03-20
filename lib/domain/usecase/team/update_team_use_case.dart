import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/i_repositories/i_team_repository.dart';

class UpdateTeamUseCase {
  final ITeamRepository _teamRepository;

  UpdateTeamUseCase(this._teamRepository);

  Future<Either<Failure, void>> call(Team team, AuthUser user) async {
    if (user.teamRoles[team.id] != UserRole.admin) {
      return Left(
        PermissionFailure('You do not have permission to update this team.'),
      );
    }
    final response = await _teamRepository.updateTeam(team);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
