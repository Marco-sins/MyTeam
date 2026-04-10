import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/i_repositories/i_invitation_repository.dart';

class GetInvitationsByEmailUseCase {
  final IInvitationRepository _invitationRepository;

  GetInvitationsByEmailUseCase(this._invitationRepository);

  Future<Either<Failure, List<Invitation>>> call(String email) async {
    final response = await _invitationRepository.getInvitationsByEmail(email);
    if (response.isLeft()) {
      return response;
    }
    return Right(
      response.getOrElse(
        () => throw ServerException(message: 'Failed to get invitations'),
      ),
    );
  }
}
