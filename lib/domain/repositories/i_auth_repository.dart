import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/sign_up_success.dart';
import 'package:football_manager/domain/entities/auth_session_side_effect.dart';

abstract class IAuthRepository {
  Future<Either<Failure, AuthUser>> signIn(String email, String password);
  Future<Either<Failure, SignUpSuccess>> signUp(
    String email,
    String name,
    String password,
  );
  Future<Either<Failure, Unit>> signOut();
  Future<Either<Failure, bool>> isSignedIn();
  Future<Either<Failure, AuthUser?>> getAuthenticatedUser();
  Future<Either<Failure, Unit>> requestPasswordReset(String email);
  Future<Either<Failure, Unit>> updatePassword(String newPassword);
  Stream<AuthSessionSideEffect> watchSessionSideEffects();
}
