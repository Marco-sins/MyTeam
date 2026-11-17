import 'package:football_manager/domain/entities/match_lineup.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';

class MatchLineupModel extends MatchLineup {
  const MatchLineupModel({
    required super.id,
    required super.playerId,
    required super.matchId,
    required super.isStarting,
    super.minutesPlayed,
    super.position,
    super.initialPosition,
    super.rating,
  });

  factory MatchLineupModel.fromJson(Map<String, dynamic> json) {
    return MatchLineupModel(
      id: supabaseInt(json['id']) ?? 0,
      playerId: supabaseInt(json['player_id']) ?? 0,
      matchId: supabaseInt(json['match_id']) ?? 0,
      isStarting: json['is_start'] == true,
      minutesPlayed: supabaseInt(json['minutes_played']) ?? 0,
      position: supabaseInt(json['position']),
      initialPosition: supabaseInt(json['initial_position']),
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
    int? initialPosition,
    double? rating,
  }) {
    return MatchLineupModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      matchId: matchId ?? this.matchId,
      isStarting: isStarting ?? this.isStarting,
      minutesPlayed: minutesPlayed ?? this.minutesPlayed,
      position: position ?? this.position,
      initialPosition: initialPosition ?? this.initialPosition,
      rating: rating ?? this.rating,
    );
  }
}
