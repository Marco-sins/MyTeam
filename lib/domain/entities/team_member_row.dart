/// Miembro de equipo (fila mínima de `team_members` + datos ya resueltos en UI).
class TeamMemberRow {
  const TeamMemberRow({
    required this.userId,
    required this.role,
  });

  final String userId;
  final String role;
}
