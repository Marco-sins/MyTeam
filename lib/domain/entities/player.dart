import 'package:tfg1/domain/entities/player_position.dart';
import 'package:tfg1/domain/entities/player_statitics.dart';

class Player {
  final int id;
  final int teamId;
  final String firstName;
  final String? lastName;
  final int? number;
  final String? phone;
  final String? email;
  final List<PlayerPosition>? positions;
  final PlayerStatitics? statistics;

  Player({
    required this.id,
    required this.teamId,
    required this.firstName,
    this.lastName,
    this.number,
    this.phone,
    this.email,
    this.positions,
    this.statistics,
  });
}