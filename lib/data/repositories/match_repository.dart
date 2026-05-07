/// Repositorio para operaciones sobre `matches`.
///
/// Implementa `IMatchRepository` y encapsula la interacción con la fuente
/// remota [MatchRemoteDatasource], devolviendo `Either<Failure, T>`.
import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/utils/repository_guard.dart';
import 'package:football_manager/data/datasource/match_remote_datasource.dart';
import 'package:football_manager/data/mappers/match_lineup_mapper.dart';
import 'package:football_manager/data/mappers/match_mapper.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';
import 'package:football_manager/domain/repositories/i_match_repository.dart';

class MatchRepository implements IMatchRepository {
  final MatchRemoteDatasource _remoteDatasource;

  MatchRepository(this._remoteDatasource);

  @override
  Future<Either<Failure, Unit>> addMatchLineup(MatchLineup lineup) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.addMatchLineup(MatchLineupMapper.toModel(lineup));
      return unit;
    });
  }

  @override
  Future<Either<Failure, Match>> createMatch(Match match) {
    return runRepositoryGuard(() async {
      final created = await _remoteDatasource.createMatch(
        MatchMapper.toModel(match),
      );
      return MatchMapper.toEntity(created);
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteMatch(int id) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.deleteMatch(id);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Match>> getMatchById(int id) {
    return runRepositoryGuard(() async {
      final match = await _remoteDatasource.getMatchById(id);
      return MatchMapper.toEntity(match);
    });
  }

  @override
  Future<Either<Failure, List<Match>>> getMatches() {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getMatches();
      return result.map(MatchMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, List<Match>>> getMatchesByTeamId(int teamId) {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getMatchesByTeamId(teamId);
      return result.map(MatchMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> updateMatch(Match match) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.updateMatch(MatchMapper.toModel(match));
      return unit;
    });
  }

  @override
  Future<Either<Failure, List<MatchLineup>>> getMatchLineupsByMatchId(
    int matchId,
  ) {
    return runRepositoryGuard(() async {
      final rows = await _remoteDatasource.getMatchLineupsByMatchId(matchId);
      return rows.map(MatchLineupMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> updateMatchLineupMinutesPlayed({
    required int matchId,
    required int playerId,
    required int minutesPlayed,
  }) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.updateMatchLineupMinutesPlayed(
        matchId: matchId,
        playerId: playerId,
        minutesPlayed: minutesPlayed,
      );
      return unit;
    });
  }

  MatchStatus? _parseStatus(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in MatchStatus.values) {
      if (v.toString().split('.').last == raw) {
        return v;
      }
    }
    return null;
  }

  @override
  Future<Either<Failure, MatchStatus?>> getMatchStatus(int matchId) {
    return runRepositoryGuard(() async {
      final s = await _remoteDatasource.getMatchStatusString(matchId);
      return _parseStatus(s);
    });
  }

  @override
  Future<Either<Failure, Unit>> updateMatchStatusHalfTime(int matchId) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.updateMatchStatusHalfTime(matchId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> updateMatchStatusSecondHalf({
    required int matchId,
    required DateTime secondHalfStart,
  }) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.updateMatchStatusSecondHalf(
        matchId: matchId,
        secondHalfStart: secondHalfStart,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Set<int>>> getConvokedPlayerIdsForMatch(int matchId) {
    return runRepositoryGuard(() async {
      final ids = await _remoteDatasource.getConvokedPlayerIds(matchId);
      return ids.toSet();
    });
  }

  @override
  Future<Either<Failure, Unit>> persistMatchLineupPositions({
    required int matchId,
    required List<int> convokedPlayerIds,
    required Map<int, int> onFieldPositionByPlayerId,
  }) {
    return runRepositoryGuard(() async {
      for (final playerId in convokedPlayerIds) {
        await _remoteDatasource.updateMatchLineupPosition(
          matchId: matchId,
          playerId: playerId,
          position: onFieldPositionByPlayerId[playerId],
        );
      }
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> updateMatchLineupStarters({
    required int matchId,
    required List<int> starterPlayerIds,
  }) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.setAllLineupNotStarters(matchId);
      for (final playerId in starterPlayerIds) {
        await _remoteDatasource.setLineupStarter(
          matchId: matchId,
          playerId: playerId,
          isStart: true,
        );
      }
      return unit;
    });
  }

  @override
  Future<Either<Failure, List<({int playerId, int positionIndex})>>>
  getMatchLineupPositions(int matchId) {
    return runRepositoryGuard(
      () => _remoteDatasource.getLineupPositions(matchId),
    );
  }
}
