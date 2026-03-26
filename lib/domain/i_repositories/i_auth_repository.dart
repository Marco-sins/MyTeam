import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';

abstract class IAuthRepository {
  Future<Either<Failure, AuthUser>> signIn(String email, String password);
  Future<Either<Failure, AuthUser>> signUp(
    String email,
    String name,
    String password,
  );
  Future<Either<Failure, Unit>> signOut();
  Future<Either<Failure, bool>> isSignedIn();
  Future<Either<Failure, AuthUser?>> getAuthenticatedUser();
}
