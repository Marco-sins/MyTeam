import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/auth_server_exception.dart';
import 'package:tfg1/core/errors/exception/server_exception.dart';
import 'package:tfg1/core/errors/exception/unknow_exception.dart';
import 'package:tfg1/data/models/auth_user_model.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';

class AuthRemoteDatasource {
  final SupabaseClient _supabase;

  AuthRemoteDatasource(this._supabase);

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
      return AuthUserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? '',
        teamRoles:
            (Map<String, dynamic>.from(
              user.userMetadata?['teamRoles'] ?? {},
            )).map(
              (key, value) =>
                  MapEntry(int.parse(key), UserRole.fromString(value)),
            ),
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
        data: {
          'name': name,
          'teamRoles': {}, // Inicialmente sin roles de equipo
        },
      );
      final user = response.user;
      if (response.session == null || user == null) {
        throw ServerException(message: 'Failed to sign up');
      }
      return AuthUserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? '',
        teamRoles:
            (Map<String, dynamic>.from(
              user.userMetadata?['teamRoles'] ?? {},
            )).map(
              (key, value) =>
                  MapEntry(int.parse(key), UserRole.fromString(value)),
            ),
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
      return AuthUserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? '',
        teamRoles:
            (Map<String, dynamic>.from(
              user.userMetadata?['teamRoles'] ?? {},
            )).map(
              (key, value) =>
                  MapEntry(int.parse(key), UserRole.fromString(value)),
            ),
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
