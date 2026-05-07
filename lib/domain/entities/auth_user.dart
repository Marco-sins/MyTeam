import 'package:football_manager/domain/entities/enum/user_role.dart';

/// Representa al usuario autenticado y sus roles por equipo.
class AuthUser {
  final String id;
  final String email;
  final String name;
  final Map<int, UserRole> teamRoles;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.teamRoles,
  });
}
