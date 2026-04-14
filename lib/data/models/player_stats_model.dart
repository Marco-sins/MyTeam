import 'package:football_manager/domain/entities/player_stats.dart';

class PlayerStatsModel extends PlayerStats {
  const PlayerStatsModel({
    super.id,
    super.playerId,
    super.goals,
    super.assists,
    super.yellowCards,
    super.redCards,
    super.matchesPlayed,
    super.minutesPlayed,
    super.timesStarted,
  });

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerStatsModel(
      id: json['id'],
      // En base de datos la columna es "player_id"
      playerId: json['player_id'] ?? json['playerId'],
      goals: json['goals'] ?? 0,
      // En BD la columna es "assistences"; aceptamos también "assists" por compatibilidad.
      assists: json['assistences'] ?? json['assists'] ?? 0,
      yellowCards: json['yellow_cards'] ?? json['yellowCards'] ?? 0,
      redCards: json['red_cards'] ?? json['redCards'] ?? 0,
      matchesPlayed: json['matches_played'] ?? json['matchesPlayed'] ?? 0,
      minutesPlayed: json['minutes_played'] ?? json['minutesPlayed'] ?? 0,
      timesStarted: json['times_started'] ?? json['timesStarted'] ?? 0,
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
      'minutes_played': minutesPlayed,
      'times_started': timesStarted,
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
    int? minutesPlayed,
    int? timesStarted,
  }) {
    return PlayerStatsModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      minutesPlayed: minutesPlayed ?? this.minutesPlayed,
      timesStarted: timesStarted ?? this.timesStarted,
    );
  }
}
