import 'package:tfg1/domain/entities/match_lineup.dart';

class MatchLineupModel extends MatchLineup {
  const MatchLineupModel({
    required super.id,
    required super.playerId,
    required super.matchId,
    required super.isStarting,
    super.minutesPlayed,
    super.rating,
  });

  factory MatchLineupModel.fromJson(Map<String, dynamic> json) {
    return MatchLineupModel(
      id: json['id'],
      playerId: json['playerId'],
      matchId: json['matchId'],
      isStarting: json['isStarting'],
      minutesPlayed: json['minutesPlayed'] ?? 0,
      rating: json['rating'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'matchId': matchId,
      'isStarting': isStarting,
      'minutesPlayed': minutesPlayed,
      'rating': rating,
    };
  }

  MatchLineupModel copyWith({
    int? id,
    int? playerId,
    int? matchId,
    bool? isStarting,
    int? minutesPlayed,
    double? rating,
  }) {
    return MatchLineupModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      matchId: matchId ?? this.matchId,
      isStarting: isStarting ?? this.isStarting,
      minutesPlayed: minutesPlayed ?? this.minutesPlayed,
      rating: rating ?? this.rating,
    );
  }
}
