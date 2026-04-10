import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/server_failure.dart';
import 'package:football_manager/core/errors/failure/unknow_failure.dart';
import 'package:football_manager/data/datasource/profile_remote_datasource.dart';
import 'package:football_manager/domain/entities/profile.dart';
import 'package:football_manager/domain/i_repositories/i_profile_repository.dart';

class ProfileRepository implements IProfileRepository {
  final ProfileRemoteDatasource _datasource;

  ProfileRepository(this._datasource);

  @override
  Future<Either<Failure, List<Profile>>> getProfilesByIds(
    List<String> ids,
  ) async {
    try {
      final result = await _datasource.getProfilesByIds(ids);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }
}
