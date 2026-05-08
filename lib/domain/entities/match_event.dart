/// Entidad de dominio que representa un evento del partido (gol, falta,
/// tarjeta, sustitución, etc.).
///
/// Incluye una fábrica `fromSupabaseMap` que normaliza filas de PostgREST y
/// resuelve el `minute` mediante utilidades de `supabase_dynamic`.
library;

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
  final double? point;

  const MatchEvent({
    required this.id,
    required this.matchId,
    this.playerId1,
    this.playerId2,
    required this.minute,
    required this.type,
    this.note,
    this.point,
  });

  /// Construye la entidad desde una fila JSON de Supabase (p. ej. evento en vivo).
  factory MatchEvent.fromSupabaseMap(Map<String, dynamic> json) {
    final rawType = json['type'];
    final String? typeString = rawType?.toString().split('.').last;
    final MatchEventEnum parsedType = typeString != null
        ? MatchEventEnum.values.firstWhere(
            (e) => e.toString().split('.').last == typeString,
            orElse: () => MatchEventEnum.scoreGoal,
          )
        : MatchEventEnum.scoreGoal;

    return MatchEvent(
      id: supabaseInt(json['id']) ?? 0,
      matchId: supabaseInt(json['match_id']) ?? 0,
      playerId1: supabaseInt(json['player_id1']),
      playerId2: supabaseInt(json['player_id2']),
      type: parsedType,
      minute: resolveMatchEventMinute(json),
      note: json['note'] as String?,
      point: (json['point'] as num?)?.toDouble(),
    );
  }
}
