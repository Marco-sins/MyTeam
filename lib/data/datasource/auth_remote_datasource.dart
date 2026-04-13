import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/auth_server_exception.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/auth_user_model.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';

class AuthRemoteDatasource {
  final SupabaseClient _supabase;

  AuthRemoteDatasource(this._supabase);

  Future<Map<int, UserRole>> _getTeamRolesForUser(String userId) async {
    try {
      final List<dynamic> rows = await _supabase
          .from('team_members')
          .select('id_team, role')
          .eq('id_user', userId);

      final Map<int, UserRole> roles = {};
      for (final row in rows) {
        final int teamId = row['id_team'] as int;
        final String roleStr = (row['role'] as String?) ?? 'external';
        try {
          roles[teamId] = UserRole.fromString(roleStr);
        } catch (_) {
          // Ignorar roles no válidos en la base de datos
        }
      }
      return roles;
    } catch (_) {
      // Si algo falla al cargar los roles, devolvemos un mapa vacío
      return {};
    }
  }

  Future<AuthUserModel> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (response.session == null || user == null) {
        throw Exception('Failed to sign in');
      }
      final teamRoles = await _getTeamRolesForUser(user.id);
      return AuthUserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? '',
        teamRoles: teamRoles,
      );
    } on AuthException catch (e) {
      throw AuthServerException('Authentication error: ${e.message}');
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw AuthServerException('Sign out error: ${e.message}');
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<AuthUserModel> signUp(
    String email,
    String name,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'com.example.tfg1://login',
        data: {
          'name': name,
          'teamRoles': {}, // Inicialmente sin roles de equipo
        },
      );
      final user = response.user;
      if (response.session == null || user == null) {
        throw ServerException(message: 'Failed to sign up');
      }

      // Crear también la fila en la tabla de perfiles con el mismo id
      try {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'username': name,
          'email': user.email ?? email,
        });
      } on PostgrestException catch (e) {
        // Si falla la creación del perfil, consideramos que es un error de servidor
        throw ServerException(message: e.message, code: e.code);
      }

      final teamRoles = await _getTeamRolesForUser(user.id);
      return AuthUserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? '',
        teamRoles: teamRoles,
      );
    } on AuthException catch (e) {
      throw AuthServerException('Sign up error: ${e.message}');
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<AuthUserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }
      final teamRoles = await _getTeamRolesForUser(user.id);
      return AuthUserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? '',
        teamRoles: teamRoles,
      );
    } on AuthException catch (e) {
      throw AuthServerException('Authentication error: ${e.message}');
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      return _supabase.auth.currentUser != null;
    } on AuthException catch (e) {
      throw AuthServerException('Authentication error: ${e.message}');
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }
}
