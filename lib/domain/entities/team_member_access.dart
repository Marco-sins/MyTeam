/// Información de acceso de un miembro de equipo: role/username/email.
class TeamMemberAccess {
  final String userId;
  final String role;
  final String username;
  final String email;

  const TeamMemberAccess({
    required this.userId,
    required this.role,
    this.username = '',
    this.email = '',
  });
}
