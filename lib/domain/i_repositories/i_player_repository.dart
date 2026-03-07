import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/player_position.dart';

abstract class IPlayerRepository {
  Future<List<Player>> getPlayers();
  Future<Player> getPlayerById(int id);
  Future<void> addPlayer(Player player);
  Future<void> updatePlayer(Player player);
  Future<void> deletePlayer(int id);
  Future<List<Player>> getPlayersByTeamId(int teamId);
  Future<List<Player>> getPlayersByPosition(int teamId, PlayerPosition position);
  Future<List<Player>> getPlayerByName(int teamId, String name);
  Future<List<Player>> getPlayersByNumber(int teamId, int number);
  Future<List<Player>> getPlayerByMatchId(int matchId);
}