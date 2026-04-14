import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/team_model.dart';

class TeamRemoteDatasource {
  final SupabaseClient _supabase;

  TeamRemoteDatasource(this._supabase);

  static const String _logoBucket = 'team-logos';

  String? _extractStoragePathFromPublicUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_logoBucket);
      if (bucketIndex == -1 || bucketIndex == segments.length - 1) {
        return null;
      }
      return segments.sublist(bucketIndex + 1).join('/');
    } catch (_) {
      return null;
    }
  }

  Future<void> removeSelfFromTeam({
    required int teamId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('team_members')
          .delete()
          .eq('id_team', teamId)
          .eq('id_user', userId)
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'No se ha podido abandonar el equipo (sin filas eliminadas).',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> createTeam(TeamModel teamData) async {
    try {
      final response2 = await _supabase
          .from('teams')
          .insert(teamData.toJson())
          .select('id');
      if (response2.isEmpty) {
        throw ServerException(message: 'Failed to create team', code: '500');
      }
      final response = await _supabase.from('team_members').insert({
        'id_user': _supabase.auth.currentUser?.id,
        'id_team': response2[0]['id'],
        'role': 'admin',
      }).select();
      if (response.isEmpty) {
        throw ServerException(message: 'Failed to create team', code: '500');
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<String> uploadLogo(Uint8List bytes, String fileName) async {
    try {
      final sanitizedFileName = fileName.replaceAll(' ', '_');
      final path =
          '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

      await _supabase.storage
          .from(_logoBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );

      final publicUrl = _supabase.storage.from(_logoBucket).getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      throw ServerException(message: e.message, code: e.statusCode.toString());
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  /// Borra filas que referencian al equipo para evitar que la BD intente
  /// poner `team_id` a NULL en tablas NOT NULL (p. ej. `matches`).
  Future<void> _purgeTeamRelatedRows(int teamId) async {
    final matchesRows = await _supabase
        .from('matches')
        .select('id')
        .eq('team_id', teamId);

    final List<int> matchIds = (matchesRows as List<dynamic>)
        .map((e) => (e as Map)['id'] as int)
        .toList();

    if (matchIds.isNotEmpty) {
      await _supabase
          .from('match_events')
          .delete()
          .inFilter('match_id', matchIds);
      await _supabase
          .from('match_lineup')
          .delete()
          .inFilter('match_id', matchIds);
    }

    await _supabase.from('matches').delete().eq('team_id', teamId);
    await _supabase.from('attendances').delete().eq('team_id', teamId);
    await _supabase.from('invitation').delete().eq('id_team', teamId);
    await _supabase.from('team_members').delete().eq('id_team', teamId);

    final playersRes = await _supabase
        .from('players')
        .select('id')
        .eq('team_id', teamId);
    final playerIds = (playersRes as List<dynamic>)
        .map((e) => (e as Map)['id'] as int)
        .toList();
    if (playerIds.isNotEmpty) {
      await _supabase
          .from('player_stats')
          .delete()
          .inFilter('player_id', playerIds);
    }
    await _supabase.from('players').delete().eq('team_id', teamId);
  }

  Future<void> deleteTeam(int id) async {
    try {
      // Obtener el logo actual para poder eliminarlo del storage si existe
      final existing = await _supabase
          .from('teams')
          .select('logo_url')
          .eq('id', id)
          .maybeSingle();

      final logoUrl = existing != null ? existing['logo_url'] as String? : null;
      if (logoUrl != null) {
        final path = _extractStoragePathFromPublicUrl(logoUrl);
        if (path != null) {
          await _supabase.storage.from(_logoBucket).remove([path]);
        }
      }

      await _purgeTeamRelatedRows(id);

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
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw ServerException(message: 'User not authenticated', code: '401');
      }
      print(
        'Current user ID: $currentUserId',
      ); // Debug: Verificar ID del usuario actual

      // 1) Obtenemos los IDs de equipos asociados al usuario actual
      final memberRows = await _supabase
          .from('team_members')
          .select('id_team')
          .eq('id_user', currentUserId);

      if (memberRows.isEmpty) {
        return [];
      }

      final teamIds = memberRows
          .map<int>((row) => row['id_team'] as int)
          .toList();

      // 2) Obtenemos sólo esos equipos
      final result = await _supabase
          .from('teams')
          .select()
          .inFilter('id', teamIds);

      return result.map<TeamModel>((e) => TeamModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateTeam(TeamModel teamData) async {
    try {
      // Si se cambia el logo, eliminamos el anterior del storage
      final existing = await _supabase
          .from('teams')
          .select('logo_url')
          .eq('id', teamData.id)
          .maybeSingle();

      final oldLogoUrl = existing != null
          ? existing['logo_url'] as String?
          : null;
      if (oldLogoUrl != null && oldLogoUrl != teamData.logoUrl) {
        final path = _extractStoragePathFromPublicUrl(oldLogoUrl);
        if (path != null) {
          await _supabase.storage.from(_logoBucket).remove([path]);
        }
      }

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
