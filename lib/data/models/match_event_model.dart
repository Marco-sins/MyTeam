import 'package:tfg1/domain/entities/enum/match_event_enum.dart';
import 'package:tfg1/domain/entities/match_event.dart';

class MatchEventModel extends MatchEvent {
  const MatchEventModel({
    required super.id,
    required super.matchId,
    super.playerId1,
    super.playerId2,
    required super.minute,
    required super.type,
    super.note,
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    return MatchEventModel(
      id: json['id'],
      matchId: json['matchId'],
      playerId1: json['playerId1'],
      playerId2: json['playerId2'],
      type: json['eventType'],
      minute: json['minute'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'playerId1': playerId1,
      'playerId2': playerId2,
      'minute': minute,
      'eventType': type,
      'note': note,
    };
  }

  MatchEventModel copyWith({
    int? id,
    int? matchId,
    int? playerId1,
    int? playerId2,
    int? minute,
    MatchEventEnum? type,
    String? note,
  }) {
    return MatchEventModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId1: playerId1 ?? this.playerId1,
      playerId2: playerId2 ?? this.playerId2,
      minute: minute ?? this.minute,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }
}
