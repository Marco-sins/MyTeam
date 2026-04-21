import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/profile.dart';
import 'package:football_manager/domain/repositories/i_profile_repository.dart';

class GetProfilesByIdsUseCase {
  final IProfileRepository _profileRepository;

  GetProfilesByIdsUseCase(this._profileRepository);

  Future<Either<Failure, List<Profile>>> call(List<String> ids) {
    return _profileRepository.getProfilesByIds(ids);
  }
}
