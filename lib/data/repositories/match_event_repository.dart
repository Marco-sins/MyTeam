import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/utils/repository_guard.dart';
import 'package:football_manager/data/datasource/match_event_remote_datasource.dart';
import 'package:football_manager/data/mappers/match_event_mapper.dart';
import 'package:football_manager/data/models/match_event_model.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/entities/match_event_aggregates.dart';
import 'package:football_manager/domain/entities/match_live_timeline_row.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class MatchEventRepository implements IMatchEventRepository {
  final MatchEventRemoteDatasource _remoteDatasource;

  MatchEventRepository(this._remoteDatasource);

  @override
  Future<Either<Failure, Unit>> deleteMatchEvent(int id) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.deleteMatchEvent(id);
      return unit;
    });
  }

  @override
  Future<Either<Failure, List<MatchEvent>>> getMatchEventsByMatch(
    int matchId,
  ) {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getMatchEventsByMatch(matchId);
      return result.map(MatchEventMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, String?>> getLatestFormationNoteByMatchId(
    int matchId,
  ) {
    return runRepositoryGuard(
      () => _remoteDatasource.getLatestFormationNoteByMatchId(matchId),
    );
  }

  @override
  Future<Either<Failure, Unit>> saveMatchEvent(MatchEvent matchEvent) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.saveMatchEvent(
        MatchEventMapper.toModel(matchEvent),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> updateMatchEvent(MatchEvent matchEvent) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.updateMatchEvent(
        MatchEventMapper.toModel(matchEvent),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, MatchEventAggregates>> getEventAggregatesForMatch(
    int matchId,
  ) {
    return runRepositoryGuard(() async {
      final a = await _remoteDatasource.getEventAggregates(matchId);
      return MatchEventAggregates(
        goalsScored: a.goalsScored,
        goalsConceded: a.goalsConceded,
        shotsOur: a.shotsOur,
        shotsRival: a.shotsRival,
        foulsOur: a.foulsOur,
        foulsRival: a.foulsRival,
        cornersOur: a.cornersOur,
        cornersRival: a.cornersRival,
        yellowOur: a.yellowOur,
        yellowRival: a.yellowRival,
        redOur: a.redOur,
        redRival: a.redRival,
      );
    });
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRowsForPlayerRatings(
    int matchId,
  ) {
    return runRepositoryGuard(
      () => _remoteDatasource.getRowsForPlayerRatings(matchId),
    );
  }

  @override
  Future<Either<Failure, List<MatchLiveTimelineRow>>>
      getLiveTimelineSourceRows(int matchId) {
    return runRepositoryGuard(() async {
      final raw = await _remoteDatasource.getLiveTimelineRawRows(matchId);
      return raw.map(MatchLiveTimelineRow.fromPostgresMap).toList();
    });
  }

  @override
  Future<Either<Failure, Set<int>>> getSentOffPlayerIds(int matchId) {
    return runRepositoryGuard(() => _remoteDatasource.getSentOffPlayerIds(matchId));
  }

  @override
  Future<Either<Failure, ({int yellowCount, bool hasRed})>>
      getPlayerCardSummaryForPlayer(int matchId, int playerId) {
    return runRepositoryGuard(
      () => _remoteDatasource.getPlayerCardSummaryForPlayer(
        matchId: matchId,
        playerId: playerId,
      ),
    );
  }

  @override
  Future<Either<Failure, MatchEvent?>> getLatestEventByTypeString({
    required int matchId,
    required String typeDbValue,
  }) {
    return runRepositoryGuard(() async {
      final row = await _remoteDatasource.getLatestEventRowByType(
        matchId: matchId,
        typeDbValue: typeDbValue,
      );
      if (row == null) return null;
      return MatchEventMapper.toEntity(MatchEventModel.fromJson(row));
    });
  }
}
