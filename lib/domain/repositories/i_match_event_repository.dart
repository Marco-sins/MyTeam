import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/entities/match_event_aggregates.dart';
import 'package:football_manager/domain/entities/match_live_timeline_row.dart';

abstract class IMatchEventRepository {
  Future<Either<Failure, List<MatchEvent>>> getMatchEventsByMatch(int matchId);
  /// Nota del último evento de tipo formación (clave tipo `4-4-2`), o null.
  Future<Either<Failure, String?>> getLatestFormationNoteByMatchId(int matchId);
  Future<Either<Failure, Unit>> saveMatchEvent(MatchEvent matchEvent);
  Future<Either<Failure, Unit>> updateMatchEvent(MatchEvent matchEvent);
  Future<Either<Failure, Unit>> deleteMatchEvent(int id);

  Future<Either<Failure, MatchEventAggregates>> getEventAggregatesForMatch(
    int matchId,
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> getRowsForPlayerRatings(
    int matchId,
  );

  Future<Either<Failure, List<MatchLiveTimelineRow>>>
      getLiveTimelineSourceRows(int matchId);

  Future<Either<Failure, Set<int>>> getSentOffPlayerIds(int matchId);

  Future<Either<Failure, ({int yellowCount, bool hasRed})>>
      getPlayerCardSummaryForPlayer(int matchId, int playerId);

  Future<Either<Failure, MatchEvent?>> getLatestEventByTypeString({
    required int matchId,
    required String typeDbValue,
  });
}