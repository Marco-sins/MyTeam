import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/entities/profile.dart';

abstract class IProfileRepository {
  Future<Either<Failure, List<Profile>>> getProfilesByIds(List<String> ids);
}
