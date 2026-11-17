import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/invitation.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';

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
      id: supabaseInt(json['id']) ?? 0,
      email: json['email']?.toString().trim() ?? '',
      teamId: supabaseInt(json['id_team']) ?? 0,
      invitedByUserId: json['invited_by']?.toString() ?? '',
      role: _parseRole(json['role']),
    );
  }

  static UserRole _parseRole(dynamic raw) {
    try {
      return UserRole.fromString(raw?.toString() ?? 'external');
    } on ArgumentError {
      return UserRole.external;
    }
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
