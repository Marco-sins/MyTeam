import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/entities/player_stats.dart';

/// Entidad `Player` con información personal, dorsal, posiciones y estadísticas
/// derivadas. Usada por la UI y la lógica de partidos/jugadores.
class Player {
  final int id;
  final int teamId;
  final String firstName;
  final String? lastName;
  final int? number;
  final String? phone;
  final String? email;

  /// URL pública de la foto (p. ej. Supabase Storage); columna `img_url`.
  final String? imgUrl;
  final List<PlayerPosition>? positions;
  final PlayerStats? stats;

  const Player({
    this.id = 0,
    required this.teamId,
    required this.firstName,
    this.lastName,
    this.number,
    this.phone,
    this.email,
    this.imgUrl,
    this.positions,
    this.stats,
  });

  String get fullName {
    final ln = lastName?.trim();
    if (ln == null || ln.isEmpty) {
      return firstName.trim();
    }
    return '${firstName.trim()} $ln';
  }
}
