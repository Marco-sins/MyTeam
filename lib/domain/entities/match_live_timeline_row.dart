import 'package:football_manager/core/utils/supabase_dynamic.dart';

/// Fila normalizada para la cronología en vivo del gestor de partido.
class MatchLiveTimelineRow {
  final int id;
  final int matchId;
  final dynamic rawType;
  final int minute;
  final int? playerId1;
  final int? playerId2;
  final String? note;
  final DateTime createdAt;

  const MatchLiveTimelineRow({
    required this.id,
    required this.matchId,
    required this.rawType,
    required this.minute,
    this.playerId1,
    this.playerId2,
    this.note,
    required this.createdAt,
  });

  /// Mapa compatible con helpers de UI y [MatchEvent.fromSupabaseMap].
  Map<String, dynamic> toLegacyMap() {
    return {
      'id': id,
      'match_id': matchId,
      'type': rawType,
      'minute': minute,
      'player_id1': playerId1,
      'player_id2': playerId2,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MatchLiveTimelineRow.fromPostgresMap(Map<String, dynamic> m) {
    final map = Map<String, dynamic>.from(m);
    map['minute'] = resolveMatchEventMinute(map);
    final id1 = supabaseInt(map['player_id1']);
    final id2 = supabaseInt(map['player_id2']);
    if (id1 != null) map['player_id1'] = id1;
    if (id2 != null) map['player_id2'] = id2;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(map['created_at'].toString());
    } catch (_) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    return MatchLiveTimelineRow(
      id: supabaseInt(map['id']) ?? 0,
      matchId: supabaseInt(map['match_id']) ?? 0,
      rawType: map['type'],
      minute: map['minute'] as int,
      playerId1: id1,
      playerId2: id2,
      note: map['note'] as String?,
      createdAt: createdAt,
    );
  }
}
