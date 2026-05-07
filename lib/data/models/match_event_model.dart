/// Modelo de persistencia para filas de la tabla `match_events`.
///
/// Extiende la entidad de dominio `MatchEvent` y aporta `fromJson`/`toJson`
/// para la interacción con Supabase/PostgREST.
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';

class MatchEventModel extends MatchEvent {
  const MatchEventModel({
    required super.id,
    required super.matchId,
    super.playerId1,
    super.playerId2,
    required super.minute,
    required super.type,
    super.note,
    super.point,
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
      point: e.point,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'player_id1': playerId1,
      'player_id2': playerId2,
      'minute': minute,
      // Guardamos la clave canónica normalizada (ej: 'scoregoal', 'rivaloffside')
      'type': canonicalMatchEventTypeKey(type),
      'note': note,
      'point': point,
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
    double? point,
  }) {
    return MatchEventModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId1: playerId1 ?? this.playerId1,
      playerId2: playerId2 ?? this.playerId2,
      minute: minute ?? this.minute,
      type: type ?? this.type,
      note: note ?? this.note,
      point: point ?? this.point,
    );
  }
}
