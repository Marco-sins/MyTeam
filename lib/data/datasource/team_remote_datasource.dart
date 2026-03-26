import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/server_exception.dart';
import 'package:tfg1/core/errors/exception/unknow_exception.dart';
import 'package:tfg1/data/models/team_model.dart';

class TeamRemoteDatasource {
  final SupabaseClient _supabase;

  TeamRemoteDatasource(this._supabase);

  Future<void> createTeam(TeamModel teamData) async {
    try {
      final response = await _supabase
          .from('team_members')
          .insert(
            {
              'user_id': _supabase.auth.currentUser?.id,
              'team_id': teamData.id,
              'role': 'admin',
            },
          )
          .select();
      if (response.isEmpty) {
        throw ServerException(message: 'Failed to create team', code: '500');
      }
      final response2 = await _supabase
          .from('teams')
          .insert(teamData.toJson())
          .select();
      if (response2.isEmpty) {
        throw ServerException(message: 'Failed to create team', code: '500');
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> deleteTeam(int id) async {
    try {
      final response = await _supabase
          .from('teams')
          .delete()
          .eq('id', id)
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Team with id $id not found',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<TeamModel> getTeamById(int id) async {
    try {
      final result = await _supabase
          .from('teams')
          .select()
          .eq('id', id)
          .single();
      return TeamModel.fromJson(result);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<TeamModel>> getTeams() async {
    try {
      final result = await _supabase.from('teams').select();
      return result.map((e) => TeamModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateTeam(TeamModel teamData) async {
    try {
      final response = await _supabase
          .from('teams')
          .update(teamData.toJson())
          .eq('id', teamData.id)
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Team with id ${teamData.id} not found',
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
