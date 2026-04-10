import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/profile.dart';
import 'package:football_manager/domain/i_repositories/i_profile_repository.dart';

class GetProfilesByIdsUseCase {
  final IProfileRepository _profileRepository;

  GetProfilesByIdsUseCase(this._profileRepository);

  Future<Either<Failure, List<Profile>>> call(List<String> ids) async {
    final response = await _profileRepository.getProfilesByIds(ids);
    if (response.isLeft()) {
      return response;
    }
    return Right(
      response.getOrElse(
        () => throw ServerException(message: 'Failed to get profiles'),
      ),
    );
  }
}
