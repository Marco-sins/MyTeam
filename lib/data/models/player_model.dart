import 'package:football_manager/data/models/player_stats_model.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/entities/player.dart';

class PlayerModel extends Player {
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
    final rawPositions = json['positions'] as String?;
    List<PlayerPosition> positions = [];
    if (rawPositions != null && rawPositions.trim().isNotEmpty) {
      positions = rawPositions
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .map((p) => PlayerPosition.values.byName(p))
          .toList();
    }

    return PlayerModel(
      id: json['id'],
      teamId: json['team_id'],
      firstName: json['firstname'],
      lastName: json['lastname'] ?? '',
      number: json['number'] ?? 0,
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      positions: positions,
      stats: json['stats'] != null
          ? PlayerStatsModel.fromJson(json['stats'])
          : const PlayerStatsModel(),
    );
  }

  Map<String, dynamic> toJson() {
    final String? positionsString = positions == null || positions!.isEmpty
        ? null
        : positions!
              .map((position) => position.toString().split('.').last)
              .join(',');

    final map = <String, dynamic>{
      'team_id': teamId,
      'firstname': firstName,
      'lastname': lastName,
      'number': number,
      'phone': phone,
      'email': email,
      'positions': positionsString,
    };

    return map;
  }

  PlayerModel copyWith({
    int? id,
    int? teamId,
    String? firstName,
    String? lastName,
    int? number,
    String? phone,
    String? email,
    List<PlayerPosition>? positions,
    PlayerStatsModel? stats,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      number: number ?? this.number,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      positions: positions ?? this.positions,
      stats: stats ?? this.stats as PlayerStatsModel?,
    );
  }
}
