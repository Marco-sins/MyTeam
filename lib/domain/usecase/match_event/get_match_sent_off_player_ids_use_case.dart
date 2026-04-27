import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class GetMatchSentOffPlayerIdsUseCase {
  GetMatchSentOffPlayerIdsUseCase(this._repository);

  final IMatchEventRepository _repository;

  Future<Either<Failure, Set<int>>> call(int matchId) =>
      _repository.getSentOffPlayerIds(matchId);
}
