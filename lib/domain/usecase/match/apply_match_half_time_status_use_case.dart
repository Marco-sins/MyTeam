import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class ApplyMatchHalfTimeStatusUseCase {
  ApplyMatchHalfTimeStatusUseCase(this._repository);

  final IMatchRepository _repository;

  Future<Either<Failure, Unit>> call(int matchId) =>
      _repository.updateMatchStatusHalfTime(matchId);
}
