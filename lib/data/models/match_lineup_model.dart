import 'package:football_manager/domain/entities/match_lineup.dart';

class MatchLineupModel extends MatchLineup {
  const MatchLineupModel({
    required super.id,
    required super.playerId,
    required super.matchId,
    required super.isStarting,
    super.minutesPlayed,
    super.position,
    super.rating,
  });

  factory MatchLineupModel.fromJson(Map<String, dynamic> json) {
    return MatchLineupModel(
      id: json['id'],
      playerId: json['player_id'],
      matchId: json['match_id'],
      isStarting: json['is_start'],
      minutesPlayed: json['minutes_played'] ?? 0,
      position: json['position'] as int?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'match_id': matchId,
      'is_start': isStarting,
      'minutes_played': minutesPlayed,
      'position': position,
      // La columna rating es smallint en BD, enviamos entero
      'rating': rating.toInt(),
    };
  }

  MatchLineupModel copyWith({
    int? id,
    int? playerId,
    int? matchId,
    bool? isStarting,
    int? minutesPlayed,
    int? position,
    double? rating,
  }) {
    return MatchLineupModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      matchId: matchId ?? this.matchId,
      isStarting: isStarting ?? this.isStarting,
      minutesPlayed: minutesPlayed ?? this.minutesPlayed,
      position: position ?? this.position,
      rating: rating ?? this.rating,
    );
  }
}
