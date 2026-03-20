import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/entities/player_stats.dart';

abstract class IPlayerRepository {
  Future<Either<Failure, List<Player>>> getPlayers();
  Future<Either<Failure, Player>> getPlayerById(int id);
  Future<Either<Failure, Unit>> createPlayer(
    Player player,
    PlayerStats playerStats,
  );
  Future<Either<Failure, Unit>> updatePlayer(Player player);
  Future<Either<Failure, Unit>> deletePlayer(int id);
  Future<Either<Failure, List<Player>>> getPlayersByTeam(int teamId);
  Future<Either<Failure, List<Player>>> getPlayersByPosition(
    int teamId,
    PlayerPosition position,
  );
  Future<Either<Failure, List<Player>>> getPlayerByName(String name);
  Future<Either<Failure, List<Player>>> getPlayersByNumber(
    int teamId,
    int number,
  );
  Future<Either<Failure, List<Player>>> getPlayerByMatchId(int matchId);
  Future<Either<Failure, Unit>> updatePlayerStats(
    int playerId,
    PlayerStats playerStats,
  );
}
