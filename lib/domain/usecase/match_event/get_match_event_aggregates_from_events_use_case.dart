import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match_event_aggregates.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class GetMatchEventAggregatesFromEventsUseCase {
  GetMatchEventAggregatesFromEventsUseCase(this._repository);

  final IMatchEventRepository _repository;

  Future<Either<Failure, MatchEventAggregates>> call(int matchId) =>
      _repository.getEventAggregatesForMatch(matchId);
}
