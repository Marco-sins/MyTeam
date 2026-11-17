import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/core/utils/repository_guard.dart';
import 'package:football_manager/data/datasource/invitation_remote_datasource.dart';
import 'package:football_manager/data/models/invitation_model.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/repositories/i_invitation_repository.dart';

class InvitationRepository implements IInvitationRepository {
  final InvitationRemoteDatasource _datasource;

  InvitationRepository(this._datasource);

  @override
  Future<Either<Failure, Unit>> createInvitation(Invitation invitation) {
    return runRepositoryGuard(() async {
      await _datasource.createInvitation(
        InvitationModel(
          id: invitation.id,
          email: invitation.email,
          teamId: invitation.teamId,
          invitedByUserId: invitation.invitedByUserId,
          role: invitation.role,
        ),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, List<Invitation>>> getInvitationsByEmail(
    String email,
  ) {
    return runRepositoryGuard(() => _datasource.getInvitationsByEmail(email));
  }

  @override
  Future<Either<Failure, Unit>> deleteInvitation(int id) {
    return runRepositoryGuard(() async {
      await _datasource.deleteInvitation(id);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> acceptInvitation(
    Invitation invitation,
    String userId,
  ) {
    return runRepositoryGuard(() async {
      await _datasource.acceptInvitation(
        invitationId: invitation.id,
        userId: userId,
        teamId: invitation.teamId,
        role: invitation.role.dbValue,
      );
      return unit;
    });
  }
}
