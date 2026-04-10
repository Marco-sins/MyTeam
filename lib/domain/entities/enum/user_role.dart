enum UserRole {
  admin,
  player,
  external;

  static UserRole fromString(String role) {
    switch (role) {
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
