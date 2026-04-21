import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';
import 'package:football_manager/domain/services/match_live_timeline_filter.dart';

class GetMatchLiveTimelineMapsUseCase {
  GetMatchLiveTimelineMapsUseCase(this._repository);

  final IMatchEventRepository _repository;

  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required int matchId,
    required bool isExternalSpectator,
  }) async {
    final res = await _repository.getLiveTimelineSourceRows(matchId);
    return res.fold(Left.new, (rows) {
      final sorted = MatchLiveTimelineFilter.filterAndSort(
        rows,
        isExternalSpectator: isExternalSpectator,
      );
      return Right(sorted.map((e) => e.toLegacyMap()).toList());
    });
  }
}
