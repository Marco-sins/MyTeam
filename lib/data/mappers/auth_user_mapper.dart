import 'package:tfg1/data/models/auth_user_model.dart';
import 'package:tfg1/domain/entities/auth_user.dart';

class AuthUserMapper {
  static AuthUserModel toModel(AuthUser user) {
    return AuthUserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      teamRoles: user.teamRoles,
    );
  }

  static AuthUser toEntity(AuthUserModel userModel) {
    return AuthUser(
      id: userModel.id,
      email: userModel.email,
      name: userModel.name,
      teamRoles: userModel.teamRoles,
    );
  }
}
