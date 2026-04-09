import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/i_repositories/i_team_repository.dart';

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
