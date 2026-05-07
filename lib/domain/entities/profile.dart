/// Entidad `Profile` con información mínima del usuario (id, username, email).
class Profile {
  final String id;
  final String username;
  final String email;

  const Profile({
    required this.id,
    required this.username,
    required this.email,
  });
}
