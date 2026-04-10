import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/invitation.dart';

abstract class IInvitationRepository {
  Future<Either<Failure, Unit>> createInvitation(Invitation invitation);
  Future<Either<Failure, List<Invitation>>> getInvitationsByEmail(String email);
  Future<Either<Failure, Unit>> deleteInvitation(int id);
  Future<Either<Failure, Unit>> acceptInvitation(
    Invitation invitation,
    String userId,
  );
}
