import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class FetchConvokedPlayerIdsForMatchUseCase {
  FetchConvokedPlayerIdsForMatchUseCase(this._repository);

  final IMatchRepository _repository;

  Future<Either<Failure, Set<int>>> call(int matchId) =>
      _repository.getConvokedPlayerIdsForMatch(matchId);
}
