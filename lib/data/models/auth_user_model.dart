/// Modelo de usuario autenticado (session) mapeado a la entidad de dominio
/// `AuthUser`.
library;

import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';

class AuthUserModel extends AuthUser {
  AuthUserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.teamRoles,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      teamRoles: (json['teamRoles'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), UserRole.fromString(value)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'teamRoles': teamRoles.map(
        (key, value) => MapEntry(key.toString(), value.dbValue),
      ),
    };
  }

  AuthUserModel copyWith({
    String? id,
    String? email,
    String? name,
    Map<int, UserRole>? teamRoles,
  }) {
    return AuthUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      teamRoles: teamRoles ?? this.teamRoles,
    );
  }
}
