import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/match_event_model.dart';

class MatchEventRemoteDatasource {
  final SupabaseClient _supabase;

  MatchEventRemoteDatasource(this._supabase);

  Future<void> deleteMatchEvent(int id) async {
    try {
      final response = await _supabase
          .from('match_events')
          .delete()
          .eq('id', id)
          .select();
      if (supabaseResponseAsList(response).isEmpty) {
        throw ServerException(
          message: 'MatchEvent with id $id not found',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<MatchEventModel>> getMatchEventsByMatch(int matchId) async {
    try {
      final result = await _supabase
          .from('match_events')
          .select()
          .eq('match_id', matchId)
          .order('minute', ascending: false)
          .order('created_at', ascending: false);
      return supabaseResponseAsList(result)
          .map((e) => MatchEventModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<String?> getLatestFormationNoteByMatchId(int matchId) async {
    try {
      final rowsRaw = await _supabase
          .from('match_events')
          .select('note')
          .eq('match_id', matchId)
          .eq('type', 'formation')
          .order('id', ascending: false)
          .limit(1);
      final rows = supabaseResponseAsList(rowsRaw);
      if (rows.isEmpty) return null;
      final raw = (rows.first as Map<String, dynamic>)['note'] as String?;
      final trimmed = raw?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<String?> getFirstFormationNoteByMatchId(int matchId) async {
    try {
      final rowsRaw = await _supabase
          .from('match_events')
          .select('note')
          .eq('match_id', matchId)
          .eq('type', 'formation')
          .order('id', ascending: true)
          .limit(1);
      final rows = supabaseResponseAsList(rowsRaw);
      if (rows.isEmpty) return null;
      final raw = (rows.first as Map<String, dynamic>)['note'] as String?;
      final trimmed = raw?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> saveMatchEvent(MatchEventModel matchEvent) async {
    try {
      final response = await _supabase
          .from('match_events')
          .insert(matchEvent.toJson())
          .select();
      if (supabaseResponseAsList(response).isEmpty) {
        throw ServerException(
          message: 'Failed to create match event',
          code: '500',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateMatchEvent(MatchEventModel matchEvent) async {
    try {
      final response = await _supabase
          .from('match_events')
          .update(matchEvent.toJson())
          .eq('id', matchEvent.id)
          .select();
      if (supabaseResponseAsList(response).isEmpty) {
        throw ServerException(
          message: 'MatchEvent with id ${matchEvent.id} not found',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<({
    int goalsScored,
    int goalsConceded,
    int shotsOur,
    int shotsRival,
    int foulsOur,
    int foulsRival,
    int cornersOur,
    int cornersRival,
    int offsidesOur,
    int offsidesRival,
    int yellowOur,
    int yellowRival,
    int redOur,
    int redRival,
  })> getEventAggregates(int matchId) async {
    try {
      final result = await _supabase
          .from('match_events')
          .select('type, player_id1')
          .eq('match_id', matchId);

      int scored = 0;
      int conceded = 0;
      int shotsOur = 0;
      int shotsRival = 0;
      int foulsOur = 0;
      int foulsRival = 0;
      int cornersOur = 0;
      int cornersRival = 0;
      int offsidesOur = 0;
      int offsidesRival = 0;
      int yellowOur = 0;
      int yellowRival = 0;
      int redOur = 0;
      int redRival = 0;
      final Map<int, int> yellowsByOurPlayer = {};
      final Map<int, int> yellowsByRivalPlayer = {};

      for (final row in supabaseResponseAsList(result)) {
        final raw = row['type'];
        if (raw == null) continue;
        final typeString = raw.toString().split('.').last;
        final p1 = supabaseInt(row['player_id1']);

        if (typeString == 'scoreGoal') {
          scored++;
          shotsOur++; // Gol a favor = tiro a puerta propio
        } else if (typeString == 'concedeGoal' || typeString == 'ownGoal') {
          conceded++;
          shotsRival++; // Gol encajado / propia = tiro a puerta del rival
        } else if (typeString == 'shot') {
          shotsOur++;
        } else if (typeString == 'rivalShot') {
          shotsRival++;
        } else if (typeString == 'foul') {
          foulsOur++;
        } else if (typeString == 'rivalFoul') {
          foulsRival++;
        } else if (typeString == 'corner') {
          cornersOur++;
        } else if (typeString == 'rivalCorner') {
          cornersRival++;
        } else if (typeString == 'offside') {
          offsidesOur++;
        } else if (typeString == 'rivalOffside') {
          offsidesRival++;
        } else if (typeString == 'yellowCard') {
          yellowOur++;
          if (p1 != null) {
            yellowsByOurPlayer[p1] = (yellowsByOurPlayer[p1] ?? 0) + 1;
          }
        } else if (typeString == 'rivalYellowCard') {
          yellowRival++;
          if (p1 != null) {
            yellowsByRivalPlayer[p1] = (yellowsByRivalPlayer[p1] ?? 0) + 1;
          }
        } else if (typeString == 'redCard') {
          redOur++;
        } else if (typeString == 'rivalRedCard') {
          redRival++;
        }
      }

      for (final c in yellowsByOurPlayer.values) {
        if (c >= 2) {
          redOur++;
        }
      }
      for (final c in yellowsByRivalPlayer.values) {
        if (c >= 2) {
          redRival++;
        }
      }

      return (
        goalsScored: scored,
        goalsConceded: conceded,
        shotsOur: shotsOur,
        shotsRival: shotsRival,
        foulsOur: foulsOur,
        foulsRival: foulsRival,
        cornersOur: cornersOur,
        cornersRival: cornersRival,
        offsidesOur: offsidesOur,
        offsidesRival: offsidesRival,
        yellowOur: yellowOur,
        yellowRival: yellowRival,
        redOur: redOur,
        redRival: redRival,
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRowsForPlayerRatings(int matchId) async {
    try {
      final result = await _supabase
          .from('match_events')
          .select('type, player_id1, player_id2, note')
          .eq('match_id', matchId);
      return supabaseResponseAsList(result)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLiveTimelineRawRows(
    int matchId,
  ) async {
    try {
      final raw = await _supabase
          .from('match_events')
          .select(
            'id, match_id, type, minute, player_id1, player_id2, note, created_at',
          )
          .eq('match_id', matchId)
          .order('minute', ascending: true)
          .order('created_at', ascending: true);
      return supabaseResponseAsList(raw)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<Set<int>> getSentOffPlayerIds(int matchId) async {
    try {
      final result = await _supabase
          .from('match_events')
          .select('type, player_id1')
          .eq('match_id', matchId);

      final Map<int, int> yellowCounts = {};
      final Set<int> sentOff = {};

      for (final row in supabaseResponseAsList(result)) {
        final raw = row['type'];
        if (raw == null) continue;
        final typeString = raw.toString().split('.').last;
        final p1 = supabaseInt(row['player_id1']);
        if (p1 == null) continue;

        if (typeString == 'redCard') {
          sentOff.add(p1);
        } else if (typeString == 'yellowCard') {
          final current = yellowCounts[p1] ?? 0;
          final next = current + 1;
          yellowCounts[p1] = next;
          if (next >= 2) {
            sentOff.add(p1);
          }
        }
      }
      return sentOff;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<({int yellowCount, bool hasRed})> getPlayerCardSummaryForPlayer({
    required int matchId,
    required int playerId,
  }) async {
    try {
      final result = await _supabase
          .from('match_events')
          .select('type, player_id1')
          .eq('match_id', matchId)
          .eq('player_id1', playerId);

      int yellowCount = 0;
      bool hasRed = false;

      for (final row in supabaseResponseAsList(result)) {
        final raw = row['type'];
        if (raw == null) continue;
        final typeString = raw.toString().split('.').last;
        if (typeString == 'yellowCard') {
          yellowCount++;
        } else if (typeString == 'redCard') {
          hasRed = true;
        }
      }

      return (yellowCount: yellowCount, hasRed: hasRed);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>?> getLatestEventRowByType({
    required int matchId,
    required String typeDbValue,
  }) async {
    try {
      final result = await _supabase
          .from('match_events')
          .select()
          .eq('match_id', matchId)
          .eq('type', typeDbValue)
          .order('id', ascending: false)
          .limit(1);
      final list = supabaseResponseAsList(result);
      if (list.isEmpty) return null;
      return Map<String, dynamic>.from(list.first as Map);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }
}
