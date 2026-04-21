import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class GetPlayerCardSummaryForMatchPlayerUseCase {
  GetPlayerCardSummaryForMatchPlayerUseCase(this._repository);

  final IMatchEventRepository _repository;

  Future<Either<Failure, ({int yellowCount, bool hasRed})>> call({
    required int matchId,
    required int playerId,
  }) =>
      _repository.getPlayerCardSummaryForPlayer(matchId, playerId);
}
