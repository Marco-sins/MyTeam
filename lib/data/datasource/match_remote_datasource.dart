import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/server_exception.dart';
import 'package:tfg1/core/errors/exception/unknow_exception.dart';
import 'package:tfg1/data/models/match_lineup_model.dart';
import 'package:tfg1/data/models/match_model.dart';

class MatchRemoteDatasource {
  final SupabaseClient _supabase;

  MatchRemoteDatasource(this._supabase);

  Future<void> createMatch(MatchModel matchData) async {
    try {
      final response = await _supabase
          .from('matches')
          .insert(matchData.toJson())
          .select();
      if (response.isEmpty) {
        throw ServerException(message: 'Failed to create match', code: '500');
      }
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
          .or('home_team_id.eq.$teamId,away_team_id.eq.$teamId');
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
          .from('match_lineups')
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
}
