import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';

class MatchEvent {
  final int id;
  final int matchId;
  final int? playerId1;
  final int? playerId2;
  final int minute;
  final MatchEventEnum type;
  final String? note;
  /// Desde Supabase; usado para ordenar la cronología igual que en el gestor.
  final DateTime? createdAt;

  const MatchEvent({
    required this.id,
    required this.matchId,
    this.playerId1,
    this.playerId2,
    required this.minute,
    required this.type,
    this.note,
    this.createdAt,
  });

  /// Misma lógica de normalización que [canonicalMatchEventTypeKey] (sin depender
  /// de mayúsculas o del formato de enum en Postgres/PostgREST).
  static String _enumNameNorm(MatchEventEnum e) {
    return e
        .toString()
        .split('.')
        .last
        .toLowerCase()
        .replaceAll('_', '');
  }

  static MatchEventEnum _parseTypeField(dynamic rawType) {
    if (rawType == null) return MatchEventEnum.scoreGoal;
    final key = canonicalMatchEventTypeKey(rawType);
    if (key.isEmpty) return MatchEventEnum.scoreGoal;
    for (final e in MatchEventEnum.values) {
      if (_enumNameNorm(e) == key) {
        return e;
      }
    }
    return MatchEventEnum.scoreGoal;
  }

  /// Construye la entidad desde una fila JSON de Supabase (p. ej. evento en vivo).
  factory MatchEvent.fromSupabaseMap(Map<String, dynamic> json) {
    final rawType = json['type'];
    final MatchEventEnum parsedType = _parseTypeField(rawType);

    DateTime? createdAt;
    try {
      final raw = json['created_at'];
      if (raw != null) {
        createdAt = DateTime.parse(raw.toString());
      }
    } catch (_) {}

    return MatchEvent(
      id: supabaseInt(json['id']) ?? 0,
      matchId: supabaseInt(json['match_id']) ?? 0,
      playerId1: supabaseInt(json['player_id1']),
      playerId2: supabaseInt(json['player_id2']),
      type: parsedType,
      minute: resolveMatchEventMinute(json),
      note: json['note']?.toString(),
      createdAt: createdAt,
    );
  }
}
