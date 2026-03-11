import 'package:tfg1/data/models/player_stats_model.dart';
import 'package:tfg1/domain/entities/enum/player_position.dart';
import 'package:tfg1/domain/entities/player.dart';

class PlayerModel extends Player{
  const PlayerModel({
    required super.id,
    required super.teamId,
    required super.firstName,
    super.lastName,
    super.number,
    super.phone,
    super.email,
    super.positions,
    PlayerStatsModel? super.stats,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'],
      teamId: json['teamId'],
      firstName: json['firstName'],
      lastName: json['lastName'] ?? '',
      number: json['number'] ?? 0,
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      positions: (json['positions'] as List?)
          ?.map((p) => PlayerPosition.values.byName(p.toString()))
          .toList() ?? [],
      stats: json['stats'] != null
          ? PlayerStatsModel.fromJson(json['stats'])
          : const PlayerStatsModel(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'firstName': firstName,
      'lastName': lastName,
      'number': number,
      'phone': phone,
      'email': email,
      'positions': positions?.map((position) => position.toString().split('.').last).toList(),
      'stats': (stats as PlayerStatsModel).toJson(),
    };
  }
}