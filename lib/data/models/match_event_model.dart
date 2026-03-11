import 'package:tfg1/domain/entities/match_event.dart';

class MatchEventModel extends MatchEvent {
  const MatchEventModel({
    required super.id,
    required super.matchId,
    super.playerId,
    super.player2Id,
    required super.minute,
    required super.type,
    super.note,
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    return MatchEventModel(
      id: json['id'],
      matchId: json['matchId'],
      playerId: json['playerId'],
      player2Id: json['playerId2'],
      type: json['eventType'],
      minute: json['minute'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'playerId': playerId,
      'player2Id': player2Id,
      'minute': minute,
      'eventType': type,
      'note': note,
    };
  }
}