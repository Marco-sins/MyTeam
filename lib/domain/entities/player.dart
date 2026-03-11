import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/entities/player_stats.dart';

class Player {
  final int id;
  final int teamId;
  final String firstName;
  final String? lastName;
  final int? number;
  final String? phone;
  final String? email;
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
    this.positions,
    this.stats,
  });

  String get fullName => lastName != null ? '$firstName $lastName' : firstName;
}