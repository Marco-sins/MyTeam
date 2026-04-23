import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/match_event.dart';

class MatchEventModel extends MatchEvent {
  const MatchEventModel({
    required super.id,
    required super.matchId,
    super.playerId1,
    super.playerId2,
    required super.minute,
    required super.type,
    super.note,
    super.createdAt,
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    final e = MatchEvent.fromSupabaseMap(json);
    return MatchEventModel(
      id: e.id,
      matchId: e.matchId,
      playerId1: e.playerId1,
      playerId2: e.playerId2,
      minute: e.minute,
      type: e.type,
      note: e.note,
      createdAt: e.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'player_id1': playerId1,
      'player_id2': playerId2,
      'minute': minute,
      // Guardamos solo el nombre del enum ("scoreGoal", "concedeGoal", etc.)
      'type': type.toString().split('.').last,
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
    DateTime? createdAt,
  }) {
    return MatchEventModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId1: playerId1 ?? this.playerId1,
      playerId2: playerId2 ?? this.playerId2,
      minute: minute ?? this.minute,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
