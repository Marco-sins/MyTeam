import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/player_model.dart';
import 'package:football_manager/data/models/player_stats_model.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';

class PlayerRemoteDatasource {
  final SupabaseClient _supabase;

  PlayerRemoteDatasource(this._supabase);

  Future<void> createPlayer(
    PlayerModel playerData,
    PlayerStatsModel playerStatsData,
  ) async {
    try {
      final response = await _supabase
          .from('players')
          .insert(playerData.toJson())
          .select();
      if (response.isEmpty) {
        throw ServerException(message: 'Failed to create player', code: '500');
      }
      final int playerId = (response as List).isNotEmpty
          ? response[0]['id'] as int
          : 0;
      final statsResponse = await _supabase
          .from('player_stats')
          .insert(playerStatsData.copyWith(playerId: playerId).toJson())
          .select();
      if (statsResponse.isEmpty) {
        throw ServerException(
          message: 'Failed to create player stats',
          code: '500',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> deletePlayer(int id) async {
    try {
      // Borramos primero el jugador; si no existe, Supabase lanzará
      // PostgrestException y la propagaremos como ServerException.
      await _supabase.from('players').delete().eq('id', id);

      // Borramos sus estadísticas si existen, pero no consideramos error
      // el hecho de que no haya fila en player_stats (puede ser opcional).
      await _supabase.from('player_stats').delete().eq('player_id', id);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<PlayerModel> getPlayerById(int id) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('id', id)
          .single();
      final playerModel = PlayerModel.fromJson(result);
      final statsResult = await _supabase
          .from('player_stats')
          .select()
          .eq('player_id', id)
          .single();
      final playerStatsModel = PlayerStatsModel.fromJson(statsResult);
      return playerModel.copyWith(stats: playerStatsModel);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayerByMatchId(int matchId) async {
    try {
      final result = await _supabase
          .from('match_lineup')
          .select('player:players(*)')
          .eq('match_id', matchId);
      final List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e['player']))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayerByName(String name) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .ilike('firstname', '%$name%');
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayers() async {
    try {
      final result = await _supabase.from('players').select();
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayersByNumber(int teamId, int number) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId)
          .eq('number', number);
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayersByPosition(
    int teamId,
    PlayerPosition position,
  ) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId)
          .ilike('positions', '%${position.name}%');
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayersByTeam(int teamId) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId);
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updatePlayer(PlayerModel player) async {
    try {
      await _supabase
          .from('players')
          .update(player.toJson())
          .eq('id', player.id);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updatePlayerStats(
    int playerId,
    PlayerStatsModel playerStats,
  ) async {
    try {
      await _supabase
          .from('player_stats')
          .update(playerStats.toJson())
          .eq('player_id', playerId);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }
}
