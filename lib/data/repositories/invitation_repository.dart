import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/server_failure.dart';
import 'package:football_manager/core/errors/failure/unknow_failure.dart';
import 'package:football_manager/data/datasource/invitation_remote_datasource.dart';
import 'package:football_manager/data/models/invitation_model.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/domain/repositories/i_invitation_repository.dart';

class InvitationRepository implements IInvitationRepository {
  final InvitationRemoteDatasource _datasource;

  InvitationRepository(this._datasource);

  @override
  Future<Either<Failure, Unit>> createInvitation(Invitation invitation) async {
    try {
      await _datasource.createInvitation(
        InvitationModel(
          id: invitation.id,
          email: invitation.email,
          teamId: invitation.teamId,
          invitedByUserId: invitation.invitedByUserId,
          role: invitation.role,
        ),
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Invitation>>> getInvitationsByEmail(
    String email,
  ) async {
    try {
      final result = await _datasource.getInvitationsByEmail(email);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteInvitation(int id) async {
    try {
      await _datasource.deleteInvitation(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptInvitation(
    Invitation invitation,
    String userId,
  ) async {
    try {
      await _datasource.acceptInvitation(
        invitationId: invitation.id,
        userId: userId,
        teamId: invitation.teamId,
        role: invitation.role.dbValue,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }
}
