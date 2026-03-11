import 'package:tfg1/domain/entities/player_stats.dart';

class PlayerStatsModel extends PlayerStats{
  const PlayerStatsModel({
    super.id,
    super.playerId,
    super.goals,
    super.assists,
    super.yellowCards,
    super.redCards,
  });

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerStatsModel(
      id: json['id'],
      playerId: json['playerId'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      yellowCards: json['yellowCards'] ?? 0,
      redCards: json['redCards'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'goals': goals,
      'assists': assists,
      'yellowCards': yellowCards,
      'redCards': redCards,
    };
  }
}