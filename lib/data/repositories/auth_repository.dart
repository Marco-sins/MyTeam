import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/utils/repository_guard.dart';
import 'package:football_manager/data/datasource/auth_remote_datasource.dart';
import 'package:football_manager/data/mappers/auth_user_mapper.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/sign_up_success.dart';
import 'package:football_manager/domain/repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepository(this._datasource);

  @override
  Future<Either<Failure, AuthUser?>> getAuthenticatedUser() {
    return runRepositoryGuard(() async {
      final userModel = await _datasource.getCurrentUser();
      if (userModel == null) return null;
      return AuthUserMapper.toEntity(userModel);
    });
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() {
    return runRepositoryGuard(_datasource.isSignedIn);
  }

  @override
  Future<Either<Failure, AuthUser>> signIn(
    String email,
    String password,
  ) {
    return runRepositoryGuard(() async {
      final response = await _datasource.signIn(email, password);
      return AuthUserMapper.toEntity(response);
    });
  }

  @override
  Future<Either<Failure, Unit>> signOut() {
    return runRepositoryGuard(() async {
      await _datasource.signOut();
      return unit;
    });
  }

  @override
  Future<Either<Failure, SignUpSuccess>> signUp(
    String email,
    String name,
    String password,
  ) {
    return runRepositoryGuard(() async {
      final raw = await _datasource.signUp(email, name, password);
      if (raw.awaitingEmailConfirmation) {
        return SignUpSuccess.awaitingEmailVerification(raw.email);
      }
      final user = AuthUserMapper.toEntity(raw.user!);
      return SignUpSuccess.authenticated(user);
    });
  }
}
