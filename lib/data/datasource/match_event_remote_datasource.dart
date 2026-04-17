import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
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
          .eq('id', id);
      if (response.isEmpty) {
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
      return result.map((e) => MatchEventModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<String?> getLatestFormationNoteByMatchId(int matchId) async {
    try {
      final rows = await _supabase
          .from('match_events')
          .select('note')
          .eq('match_id', matchId)
          .eq('type', 'formation')
          .order('id', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      final raw = rows.first['note'] as String?;
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
      if (response.isEmpty) {
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
      if (response.isEmpty) {
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
}
