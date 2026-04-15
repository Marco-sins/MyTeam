enum UserRole {
  /// Creador del equipo. Mismos permisos que [admin]; además puede expulsar a admins.
  /// No se asigna por invitación, solo al crear el equipo.
  superAdmin,
  admin,
  player,
  external;

  /// Puede gestionar plantilla, partidos, asistencia, invitaciones, etc.
  bool get hasAdminPrivileges =>
      this == UserRole.superAdmin || this == UserRole.admin;

  /// Valor almacenado en `team_members.role` y en invitaciones (Postgres / Supabase).
  String get dbValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'superadmin';
      case UserRole.admin:
        return 'admin';
      case UserRole.player:
        return 'player';
      case UserRole.external:
        return 'external';
    }
  }

  static UserRole fromString(String role) {
    final r = role.trim().toLowerCase().replaceAll('-', '_');
    switch (r) {
      case 'superadmin':
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'player':
        return UserRole.player;
      case 'external':
        return UserRole.external;
      default:
        throw ArgumentError('Invalid user role: $role');
    }
  }
}
