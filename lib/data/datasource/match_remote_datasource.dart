import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/match_lineup_model.dart';
import 'package:football_manager/data/models/match_model.dart';

class MatchRemoteDatasource {
  final SupabaseClient _supabase;

  MatchRemoteDatasource(this._supabase);

  Future<MatchModel> createMatch(MatchModel matchData) async {
    try {
      // Dejamos que la BD genere el id del partido y
      // devolvemos la fila creada para conocer su id real.
      final response = await _supabase
          .from('matches')
          .insert({
            'team_id': matchData.teamId,
            'opponent': matchData.opponent,
            'goals_scored': matchData.goalsScored,
            'goals_conceded': matchData.goalsConceded,
            'date': matchData.date.toIso8601String(),
            // Para evitar errores de formato, almacenamos "hour" también
            // como timestamp completo (mismo valor que date).
            'hour': matchData.date.toIso8601String(),
            'status': matchData.status.toString().split('.').last,
            'is_home': matchData.isHome,
          })
          .select()
          .single();

      return MatchModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> deleteMatch(int id) async {
    try {
      final response = await _supabase
          .from('matches')
          .delete()
          .eq('id', id)
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Match with id $id not found',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<MatchModel> getMatchById(int id) async {
    try {
      final result = await _supabase
          .from('matches')
          .select()
          .eq('id', id)
          .single();
      return MatchModel.fromJson(result);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<MatchModel>> getMatches() async {
    try {
      final result = await _supabase.from('matches').select();
      return result.map((e) => MatchModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<MatchModel>> getMatchesByTeamId(int teamId) async {
    try {
      final result = await _supabase
          .from('matches')
          .select()
          .eq('team_id', teamId);
      return result.map((e) => MatchModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateMatch(MatchModel matchData) async {
    try {
      final response = await _supabase
          .from('matches')
          .update(matchData.toJson())
          .eq('id', matchData.id)
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Match with id ${matchData.id} not found',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> addMatchLineup(MatchLineupModel lineup) async {
    try {
      final response = await _supabase
          // La tabla real en Supabase es 'match_lineup' (en singular)
          .from('match_lineup')
          .insert(lineup.toJson())
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Failed to add lineup to match',
          code: '500',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateMatchLineupMinutesPlayed({
    required int matchId,
    required int playerId,
    required int minutesPlayed,
  }) async {
    try {
      final response = await _supabase
          .from('match_lineup')
          .update({'minutes_played': minutesPlayed})
          .eq('match_id', matchId)
          .eq('player_id', playerId)
          .select('player_id');
      if (response.isEmpty) {
        throw ServerException(
          message: 'No se encontró la alineación del jugador $playerId',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<MatchLineupModel>> getMatchLineupsByMatchId(int matchId) async {
    try {
      final result = await _supabase
          .from('match_lineup')
          .select()
          .eq('match_id', matchId);
      return (result as List)
          .map(
            (e) => MatchLineupModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<String?> getMatchStatusString(int matchId) async {
    try {
      final row = await _supabase
          .from('matches')
          .select('status')
          .eq('id', matchId)
          .maybeSingle();
      if (row == null) return null;
      final raw = row['status'];
      if (raw == null) return null;
      return raw.toString().split('.').last;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateMatchStatusHalfTime(int matchId) async {
    try {
      await _supabase
          .from('matches')
          .update({'status': 'halfTime'})
          .eq('id', matchId);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateMatchStatusSecondHalf({
    required int matchId,
    required DateTime secondHalfStart,
  }) async {
    try {
      final iso = secondHalfStart.toIso8601String();
      await _supabase.from('matches').update({
        'status': 'secondHalf',
        'date': iso,
        'hour': iso,
      }).eq('id', matchId);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<int>> getConvokedPlayerIds(int matchId) async {
    try {
      final result = await _supabase
          .from('match_lineup')
          .select('player_id')
          .eq('match_id', matchId);
      final list = result as List<dynamic>? ?? const [];
      final ids = <int>{};
      for (final row in list) {
        final m = row as Map;
        final pid = m['player_id'];
        if (pid is int) {
          ids.add(pid);
        } else if (pid is num) {
          ids.add(pid.round());
        }
      }
      return ids.toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateMatchLineupPosition({
    required int matchId,
    required int playerId,
    required int? position,
  }) async {
    try {
      final response = await _supabase
          .from('match_lineup')
          .update({'position': position})
          .eq('match_id', matchId)
          .eq('player_id', playerId)
          .select('player_id');
      if (response.isEmpty) {
        throw ServerException(
          message: 'No se encontró la alineación del jugador $playerId',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  /// Fija alineación de salida: `initial_position` = `position` si aún no estaba fijada.
  Future<void> lockInitialLineupPositions(int matchId) async {
    try {
      final result = await _supabase
          .from('match_lineup')
          .select('player_id, position, initial_position')
          .eq('match_id', matchId);
      final list = result as List<dynamic>? ?? const [];
      for (final row in list) {
        final m = Map<String, dynamic>.from(row as Map);
        final init = m['initial_position'];
        if (init != null) continue;
        final pid = m['player_id'];
        final pos = m['position'];
        final int? playerId = pid is int ? pid : (pid as num?)?.round();
        final int? position = pos is int ? pos : (pos as num?)?.round();
        if (playerId == null || position == null) continue;
        await _supabase
            .from('match_lineup')
            .update({'initial_position': position})
            .eq('match_id', matchId)
            .eq('player_id', playerId);
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> setAllLineupNotStarters(int matchId) async {
    try {
      await _supabase
          .from('match_lineup')
          .update({'is_start': false})
          .eq('match_id', matchId);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> setLineupStarter({
    required int matchId,
    required int playerId,
    required bool isStart,
  }) async {
    try {
      await _supabase
          .from('match_lineup')
          .update({'is_start': isStart})
          .eq('match_id', matchId)
          .eq('player_id', playerId);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<({int playerId, int positionIndex})>> getLineupPositions(
    int matchId,
  ) async {
    try {
      final lineupRows = await _supabase
          .from('match_lineup')
          .select('player_id, position')
          .eq('match_id', matchId);
      final list = lineupRows as List<dynamic>? ?? const [];
      final out = <({int playerId, int positionIndex})>[];
      for (final row in list) {
        final m = row as Map;
        final pid = m['player_id'];
        final pos = m['position'];
        final int? playerId = pid is int ? pid : (pid as num?)?.round();
        final int? positionIndex = pos is int ? pos : (pos as num?)?.round();
        if (playerId == null || positionIndex == null) continue;
        out.add((playerId: playerId, positionIndex: positionIndex));
      }
      return out;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }
}
