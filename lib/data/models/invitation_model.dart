import 'package:football_manager/domain/entities/enum/user_role.dart';

/// Modelo persistente para invitaciones (`invitations`).
import 'package:football_manager/domain/entities/invitation.dart';

class InvitationModel extends Invitation {
  const InvitationModel({
    required super.id,
    required super.email,
    required super.teamId,
    required super.invitedByUserId,
    required super.role,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] as int,
      email: json['email'] as String,
      teamId: json['id_team'] as int,
      invitedByUserId: json['invited_by'] as String,
      role: UserRole.fromString(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'id_team': teamId,
      'invited_by': invitedByUserId,
      'role': role.dbValue,
    };
  }
}
