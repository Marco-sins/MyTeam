import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/config/auth_redirect_urls.dart';
import 'package:football_manager/core/errors/exception/auth_server_exception.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/auth_user_model.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';

class AuthRemoteDatasource {
  final SupabaseClient _supabase;

  AuthRemoteDatasource(this._supabase);

  /// Crea la fila en `profiles` si no existe (primer inicio de sesión o tras
  /// verificar el correo cuando el insert en el registro no pudo hacerse sin sesión).
  Future<void> _ensureProfileForAuthUser(
    User user, {
    String? preferredUsername,
  }) async {
    try {
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing != null) {
        return;
      }

      final meta = user.userMetadata;
      final metaName = meta?['name'];
      final nameStr = metaName is String ? metaName.trim() : '';
      final email = user.email ?? '';
      final fromForm = preferredUsername?.trim() ?? '';
      final username = fromForm.isNotEmpty
          ? fromForm
          : nameStr.isNotEmpty
              ? nameStr
              : (email.contains('@') ? email.split('@').first : 'Usuario');

      await _supabase.from('profiles').insert({
        'id': user.id,
        'username': username,
        'email': email,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return;
      }
      debugPrint(
        '_ensureProfileForAuthUser: ${e.message} (code: ${e.code})',
      );
    } catch (e) {
      debugPrint('_ensureProfileForAuthUser: $e');
    }
  }

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
      await _ensureProfileForAuthUser(user);
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

  /// [awaitingEmailConfirmation] true cuando Supabase exige verificar el correo
  /// y aún no hay sesión ([AuthResponse.session] == null).
  Future<({
    bool awaitingEmailConfirmation,
    AuthUserModel? user,
    String email,
  })> signUp(
    String email,
    String name,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: AuthRedirectUrls.emailConfirmation,
        data: {
          'name': name,
          'teamRoles': {}, // Inicialmente sin roles de equipo
        },
      );
      final user = response.user;
      if (user == null) {
        throw ServerException(message: 'Failed to sign up');
      }

      final resolvedEmail = user.email ?? email;

      if (response.session == null) {
        // Sin sesión (p. ej. confirmar email): el perfil se crea en el primer login.
        return (
          awaitingEmailConfirmation: true,
          user: null,
          email: resolvedEmail,
        );
      }

      await _ensureProfileForAuthUser(user, preferredUsername: name);

      final teamRoles = await _getTeamRolesForUser(user.id);
      final model = AuthUserModel(
        id: user.id,
        email: resolvedEmail,
        name: user.userMetadata?['name'] ?? '',
        teamRoles: teamRoles,
      );
      return (
        awaitingEmailConfirmation: false,
        user: model,
        email: resolvedEmail,
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
      await _ensureProfileForAuthUser(user);
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
