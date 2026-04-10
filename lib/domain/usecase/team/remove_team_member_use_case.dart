import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/i_repositories/i_team_repository.dart';

class RemoveTeamMemberUseCase {
  final ITeamRepository _teamRepository;

  RemoveTeamMemberUseCase(this._teamRepository);

  Future<Either<Failure, Unit>> call(
    int teamId,
    String userId,
    AuthUser currentUser,
  ) async {
    if (currentUser.teamRoles[teamId] != UserRole.admin) {
      return Left(
        PermissionFailure('You do not have permission to manage team access.'),
      );
    }

    return _teamRepository.removeTeamMember(teamId, userId);
  }
}
