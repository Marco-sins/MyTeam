import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/exception/server_exception.dart';
import 'package:tfg1/core/errors/exception/unknow_exception.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/data/datasource/player_remote_datasource.dart';
import 'package:tfg1/data/mappers/player_mapper.dart';
import 'package:tfg1/data/mappers/player_stats_mapper.dart';
import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/player_stats.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class PlayerRepository implements IPlayerRepository {
  final PlayerRemoteDatasource _remoteDatasource;

  PlayerRepository(this._remoteDatasource);

  @override
  Future<Either<Failure, Unit>> createPlayer(
    Player player,
    PlayerStats playerStats,
  ) async {
    try {
      await _remoteDatasource.createPlayer(
        PlayerMapper.toModel(player),
        PlayerStatsMapper.toModel(playerStats),
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePlayer(int id) async {
    try {
      await _remoteDatasource.deletePlayer(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Player>> getPlayerById(int id) async {
    try {
      final response = await _remoteDatasource.getPlayerById(id);
      Player player = PlayerMapper.toEntity(response);
      return Right(player);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayerByMatchId(int matchId) async {
    try {
      final result = await _remoteDatasource.getPlayerByMatchId(matchId);
      List<Player> players = result
          .map((e) => PlayerMapper.toEntity(e))
          .toList();
      return Right(players);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayerByName(String name) async {
    try {
      final result = await _remoteDatasource.getPlayerByName(name);
      List<Player> players = result
          .map((e) => PlayerMapper.toEntity(e))
          .toList();
      return Right(players);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayers() async {
    try {
      final response = await _remoteDatasource.getPlayers();
      List<Player> players = response
          .map((e) => PlayerMapper.toEntity(e))
          .toList();
      return Right(players);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByNumber(
    int teamId,
    int number,
  ) async {
    try {
      final result = await _remoteDatasource.getPlayersByNumber(teamId, number);
      List<Player> players = result
          .map((e) => PlayerMapper.toEntity(e))
          .toList();
      return Right(players);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByPosition(
    int teamId,
    PlayerPosition position,
  ) async {
    try {
      final result = await _remoteDatasource.getPlayersByPosition(
        teamId,
        position,
      );
      List<Player> players = result
          .map((e) => PlayerMapper.toEntity(e))
          .toList();
      return Right(players);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getPlayersByTeam(int teamId) async {
    try {
      final result = await _remoteDatasource.getPlayersByTeam(teamId);
      List<Player> players = result
          .map((e) => PlayerMapper.toEntity(e))
          .toList();
      return Right(players);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePlayer(Player player) async {
    try {
      await _remoteDatasource.updatePlayer(PlayerMapper.toModel(player));
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePlayerStats(
    int playerId,
    PlayerStats playerStats,
  ) async {
    try {
      await _remoteDatasource.updatePlayerStats(
        playerId,
        PlayerStatsMapper.toModel(playerStats),
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
