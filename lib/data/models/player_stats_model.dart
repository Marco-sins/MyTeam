import 'package:tfg1/domain/entities/player_stats.dart';

class PlayerStatsModel extends PlayerStats {
  const PlayerStatsModel({
    super.id,
    super.playerId,
    super.goals,
    super.assists,
    super.yellowCards,
    super.redCards,
    super.matchesPlayed,
  });

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerStatsModel(
      id: json['id'],
      // En base de datos la columna es "player_id"
      playerId: json['player_id'] ?? json['playerId'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      yellowCards: json['yellowCards'] ?? 0,
      redCards: json['redCards'] ?? 0,
      matchesPlayed: json['matchesPlayed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Usamos siempre "player_id" para la persistencia
      'player_id': playerId,
      'goals': goals,
      'assistences': assists,
      'yellow_cards': yellowCards,
      'red_cards': redCards,
      'matches_played': matchesPlayed,
    };
  }

  PlayerStatsModel copyWith({
    int? id,
    int? playerId,
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    int? matchesPlayed,
  }) {
    return PlayerStatsModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
    );
  }
}
