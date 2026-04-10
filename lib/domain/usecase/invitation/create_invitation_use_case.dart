import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/i_repositories/i_invitation_repository.dart';

class CreateInvitationUseCase {
  final IInvitationRepository _invitationRepository;

  CreateInvitationUseCase(this._invitationRepository);

  Future<Either<Failure, void>> call(
    Invitation invitation,
    AuthUser user,
  ) async {
    // Solo los admins del equipo pueden invitar
    if (user.teamRoles[invitation.teamId] != UserRole.admin) {
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
