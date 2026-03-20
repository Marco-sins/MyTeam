import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/exception/auth_server_exception.dart';
import 'package:tfg1/core/errors/exception/unknow_exception.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/core/errors/failure/unknow_failure.dart';
import 'package:tfg1/data/datasource/auth_remote_datasource.dart';
import 'package:tfg1/data/mappers/auth_user_mapper.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/i_repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepository(this._datasource);

  @override
  Future<Either<Failure, AuthUser>> getAuthenticatedUser() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() {
    // TODO: implement isSignedIn
    throw UnimplementedError();
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
  Future<Either<Failure, AuthUser>> signUp(
    String email,
    String name,
    String password,
  ) {
    // TODO: implement signUp
    throw UnimplementedError();
  }
}
