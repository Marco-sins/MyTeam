import 'package:football_manager/core/utils/supabase_dynamic.dart';
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
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    // En la BD solo hay un campo de tipo ("type"), lo normalizamos
    // para aceptar tanto "scoreGoal" como "MatchEventEnum.scoreGoal".
    final rawType = json['type'];
    final String? typeString = rawType?.toString().split('.').last;
    final MatchEventEnum parsedType = typeString != null
        ? MatchEventEnum.values.firstWhere(
            (e) => e.toString().split('.').last == typeString,
            orElse: () => MatchEventEnum.scoreGoal,
          )
        : MatchEventEnum.scoreGoal;

    return MatchEventModel(
      id: supabaseInt(json['id']) ?? 0,
      matchId: supabaseInt(json['match_id']) ?? 0,
      playerId1: supabaseInt(json['player_id1']),
      playerId2: supabaseInt(json['player_id2']),
      type: parsedType,
      minute: supabaseInt(json['minute']) ?? 0,
      note: json['note'] as String?,
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
