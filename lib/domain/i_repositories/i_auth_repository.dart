import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';

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
