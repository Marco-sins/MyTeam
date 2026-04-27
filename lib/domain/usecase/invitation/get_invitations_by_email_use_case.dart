import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/repositories/i_invitation_repository.dart';

class GetInvitationsByEmailUseCase {
  final IInvitationRepository _invitationRepository;

  GetInvitationsByEmailUseCase(this._invitationRepository);

  Future<Either<Failure, List<Invitation>>> call(String email) {
    return _invitationRepository.getInvitationsByEmail(email);
  }
}
