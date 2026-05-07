/// Datasource remoto para `profiles` (perfiles de usuario).
///
/// Provee consultas de perfiles por id, búsqueda y cargas auxiliares.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/profile_model.dart';

class ProfileRemoteDatasource {
  final SupabaseClient _supabase;

  ProfileRemoteDatasource(this._supabase);

  Future<List<ProfileModel>> getProfilesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final rows = await _supabase
          .from('profiles')
          .select('id, username, email')
          .inFilter('id', ids);

      return (rows as List)
          .map((row) => ProfileModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }
}
