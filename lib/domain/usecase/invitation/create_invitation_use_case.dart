import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/repositories/i_invitation_repository.dart';

class CreateInvitationUseCase {
  final IInvitationRepository _invitationRepository;

  CreateInvitationUseCase(this._invitationRepository);

  Future<Either<Failure, void>> call(
    Invitation invitation,
    AuthUser user,
  ) async {
    if (invitation.role == UserRole.superAdmin) {
      return Left(
        PermissionFailure('El rol superadmin no se puede asignar por invitación.'),
      );
    }
    final teamRole = user.teamRoles[invitation.teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure('You do not have permission to invite users.'),
      );
    }
    final response = await _invitationRepository.createInvitation(invitation);
    if (response.isLeft()) {
      return response as Left<Failure, void>;
    }
    return const Right(null);
  }
}
