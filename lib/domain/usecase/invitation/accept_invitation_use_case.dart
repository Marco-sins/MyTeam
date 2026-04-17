import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/repositories/i_invitation_repository.dart';

class AcceptInvitationUseCase {
  final IInvitationRepository _invitationRepository;

  AcceptInvitationUseCase(this._invitationRepository);

  Future<Either<Failure, void>> call(
    Invitation invitation,
    AuthUser user,
  ) async {
    // Solo el email destinatario puede aceptar
    if (invitation.email.toLowerCase() != user.email.toLowerCase()) {
      return Left(
        PermissionFailure(
          'You do not have permission to accept this invitation.',
        ),
      );
    }

    final response = await _invitationRepository.acceptInvitation(
      invitation,
      user.id,
    );
    if (response.isLeft()) {
      return response as Left<Failure, void>;
    }
    return const Right(null);
  }
}
