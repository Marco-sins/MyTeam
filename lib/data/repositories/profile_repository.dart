import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/core/utils/repository_guard.dart';
import 'package:football_manager/data/datasource/profile_remote_datasource.dart';
import 'package:football_manager/domain/entities/profile.dart';
import 'package:football_manager/domain/repositories/i_profile_repository.dart';

class ProfileRepository implements IProfileRepository {
  final ProfileRemoteDatasource _datasource;

  ProfileRepository(this._datasource);

  @override
  Future<Either<Failure, List<Profile>>> getProfilesByIds(
    List<String> ids,
  ) {
    return runRepositoryGuard(() => _datasource.getProfilesByIds(ids));
  }
}
