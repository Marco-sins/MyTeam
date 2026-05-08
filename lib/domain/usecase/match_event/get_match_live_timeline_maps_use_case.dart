/// Caso de uso que obtiene las filas crudas de la cronología en vivo del partido
/// (ordenadas) y las transforma para consumo de la UI.
library;

import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';
import 'package:football_manager/domain/services/match_live_timeline_filter.dart';

class GetMatchLiveTimelineMapsUseCase {
  GetMatchLiveTimelineMapsUseCase(this._repository);

  final IMatchEventRepository _repository;

  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required int matchId,
    bool includeAll = false,
  }) async {
    final res = await _repository.getLiveTimelineSourceRows(matchId);
    return res.fold(Left.new, (rows) {
      if (includeAll) {
        final secondHalfStart = MatchLiveTimelineFilter.resolveSecondHalfStart(
          rows,
        );
        rows.sort(
          (a, b) => MatchLiveTimelineFilter.compareDisplayOrder(
            a,
            b,
            secondHalfStart,
          ),
        );
        return Right(rows.map((e) => e.toLegacyMap()).toList());
      }

      final sorted = MatchLiveTimelineFilter.filterAndSort(rows);
      return Right(sorted.map((e) => e.toLegacyMap()).toList());
    });
  }
}
