import 'package:football_manager/domain/entities/enum/user_role.dart';

/// Entidad que representa una invitación a un equipo y el rol propuesto.
class Invitation {
  final int id;
  final String email;
  final int teamId;
  final String invitedByUserId;
  final UserRole role;

  const Invitation({
    this.id = 0,
    required this.email,
    required this.teamId,
    required this.invitedByUserId,
    required this.role,
  });
}
