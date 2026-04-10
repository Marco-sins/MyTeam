import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/invitation_model.dart';

class InvitationRemoteDatasource {
  final SupabaseClient _supabase;

  InvitationRemoteDatasource(this._supabase);

  Future<void> createInvitation(InvitationModel invitation) async {
    try {
      final response = await _supabase
          .from('invitation')
          .insert(invitation.toJson())
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Failed to create invitation',
          code: '500',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<InvitationModel>> getInvitationsByEmail(String email) async {
    try {
      final rows = await _supabase
          .from('invitation')
          .select('id, email, id_team, invited_by, role')
          .eq('email', email);

      return (rows as List)
          .map((row) => InvitationModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> deleteInvitation(int id) async {
    try {
      final response = await _supabase
          .from('invitation')
          .delete()
          .eq('id', id)
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Invitation with id $id not found',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> acceptInvitation({
    required int invitationId,
    required String userId,
    required int teamId,
    required String role,
  }) async {
    try {
      // Insertar acceso en team_members
      final memberResponse = await _supabase.from('team_members').insert({
        'id_user': userId,
        'id_team': teamId,
        'role': role,
      }).select();
      if (memberResponse.isEmpty) {
        throw ServerException(
          message: 'Failed to add user to team_members',
          code: '500',
        );
      }

      // Borrar la invitación
      final deleteResponse = await _supabase
          .from('invitation')
          .delete()
          .eq('id', invitationId)
          .select();
      if (deleteResponse.isEmpty) {
        throw ServerException(
          message: 'Failed to delete invitation after accepting',
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
