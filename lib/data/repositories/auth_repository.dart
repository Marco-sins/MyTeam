import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/auth_server_exception.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/server_failure.dart';
import 'package:football_manager/core/errors/failure/unknow_failure.dart';
import 'package:football_manager/data/datasource/auth_remote_datasource.dart';
import 'package:football_manager/data/mappers/auth_user_mapper.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/sign_up_success.dart';
import 'package:football_manager/domain/i_repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepository(this._datasource);

  @override
  Future<Either<Failure, AuthUser?>> getAuthenticatedUser() async {
    try {
      final userModel = await _datasource.getCurrentUser();
      if (userModel == null) {
        return const Right(null);
      }
      final user = AuthUserMapper.toEntity(userModel);
      return Right(user);
    } on AuthServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() async {
    try {
      final signedIn = await _datasource.isSignedIn();
      return Right(signedIn);
    } on AuthServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await _datasource.signIn(email, password);
      final user = AuthUserMapper.toEntity(response);
      return Right(user);
    } on AuthServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _datasource.signOut();
      return Right(unit);
    } on AuthServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, SignUpSuccess>> signUp(
    String email,
    String name,
    String password,
  ) async {
    try {
      final raw = await _datasource.signUp(email, name, password);
      if (raw.awaitingEmailConfirmation) {
        return Right(SignUpSuccess.awaitingEmailVerification(raw.email));
      }
      final user = AuthUserMapper.toEntity(raw.user!);
      return Right(SignUpSuccess.authenticated(user));
    } on AuthServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }
}
