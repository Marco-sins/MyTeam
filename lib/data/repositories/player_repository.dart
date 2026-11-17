import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/core/utils/repository_guard.dart';
import 'package:football_manager/data/datasource/player_remote_datasource.dart';
import 'package:football_manager/data/mappers/player_mapper.dart';
import 'package:football_manager/data/mappers/player_stats_mapper.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';

class PlayerRepository implements IPlayerRepository {
  final PlayerRemoteDatasource _remoteDatasource;

  PlayerRepository(this._remoteDatasource);

  @override
  Future<Either<Failure, Player>> createPlayer(
    Player player,
    PlayerStats playerStats,
  ) {
    return runRepositoryGuard(() async {
      final created = await _remoteDatasource.createPlayer(
        PlayerMapper.toModel(player),
        PlayerStatsMapper.toModel(playerStats),
      );
      return PlayerMapper.toEntity(created);
    });
  }

  @override
  Future<Either<Failure, Unit>> deletePlayer(int id) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.deletePlayer(id);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Player>> getPlayerById(int id) {
    return runRepositoryGuard(() async {
      final response = await _remoteDatasource.getPlayerById(id);
      return PlayerMapper.toEntity(response);
    });
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayerByMatchId(int matchId) {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getPlayerByMatchId(matchId);
      return result.map(PlayerMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayerByName(String name) {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getPlayerByName(name);
      return result.map(PlayerMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayers() {
    return runRepositoryGuard(() async {
      final response = await _remoteDatasource.getPlayers();
      return response.map(PlayerMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByNumber(
    int teamId,
    int number,
  ) {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getPlayersByNumber(teamId, number);
      return result.map(PlayerMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByPosition(
    int teamId,
    PlayerPosition position,
  ) {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getPlayersByPosition(
        teamId,
        position,
      );
      return result.map(PlayerMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByTeam(int teamId) {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getPlayersByTeam(teamId);
      return result.map(PlayerMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> updatePlayer(Player player) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.updatePlayer(PlayerMapper.toModel(player));
      return unit;
    });
  }

  @override
  Future<Either<Failure, String>> uploadPlayerPhoto({
    required Uint8List bytes,
    required String fileName,
    required int teamId,
    int? playerId,
  }) {
    return runRepositoryGuard(() async {
      return _remoteDatasource.uploadPlayerPhoto(
        bytes: bytes,
        fileName: fileName,
        teamId: teamId,
        playerId: playerId,
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteStoredPlayerPhoto(String? publicUrl) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.removePlayerPhotoIfInBucket(publicUrl);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> updatePlayerStats(
    int playerId,
    PlayerStats playerStats,
  ) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.updatePlayerStats(
        playerId,
        PlayerStatsMapper.toModel(playerStats),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> syncParticipationStatsForTeam(int teamId) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.syncParticipationStatsForTeam(teamId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> recalculateAllAggregatedStatsForTeam(
    int teamId,
  ) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.recalculateAllAggregatedStatsForTeam(teamId);
      return unit;
    });
  }
}
