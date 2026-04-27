import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class GetLiveMatchGoalTallyFromEventsUseCase {
  GetLiveMatchGoalTallyFromEventsUseCase(this._matchEventRepository);

  final IMatchEventRepository _matchEventRepository;

  Future<Either<Failure, ({int goalsScored, int goalsConceded})>> call(
    int matchId,
  ) {
    return _matchEventRepository.getLiveGoalTallyFromEventRows(matchId);
  }
}
