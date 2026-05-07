import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/domain/entities/match_live_timeline_row.dart';

/// Filtra y ordena eventos para la lista en vivo (dominio, sin Supabase).
class MatchLiveTimelineFilter {
  MatchLiveTimelineFilter._();

  /// Acciones de jugador que **sí** entran en la cronología (además de goles,
  /// sustituciones, tarjetas y cambios de periodo).
  ///
  /// No se listan: buena parada ([goodsave]), cantada ([cantada]), córners /
  /// contadores manuales, ni tiro / recuperación / pases / jugadas (solo mal pase
  /// y falta entre acciones de campo).
  static const Set<String> _playerActionTimelineKeys = {'badpass', 'foul'};

  static const Set<String> _hiddenPlayerActionKeys = {'goodsave', 'cantada'};

  /// Notas de [statusChange] que marcan tiempo de partido (no acciones de jugador).
  static bool isMatchTimeStatusNote(String? note) {
    if (note == null || note.isEmpty) return false;
    final lower = note.trim().toLowerCase();
    const allowed = [
      'inicio 1ª parte',
      'inicio 1a parte',
      'descanso',
      'inicio 2ª parte',
      'inicio 2a parte',
      'final del partido',
    ];
    return allowed.any((n) => lower == n.toLowerCase());
  }

  static bool noteIndicatesSecondHalfKickoff(String? note) {
    if (note == null || note.isEmpty) return false;
    final n = note.toLowerCase();
    return n.contains('inicio') && n.contains('2') && n.contains('parte');
  }

  /// Cronología visible: goles, sustituciones, tiempo de partido, tarjetas y
  /// solo mal pase y falta entre acciones de campo (no tiro, recuperación, etc.).
  static bool shouldIncludeRow(MatchLiveTimelineRow row) {
    final key = canonicalMatchEventTypeKey(row.rawType);
    if (key == 'formation') return false;
    if (key == 'substitution') {
      return row.minute > 0 && row.playerId1 != null && row.playerId2 != null;
    }
    if (key == 'scoregoal' || key == 'concedegoal' || key == 'owngoal') {
      return true;
    }
    if (key == 'yellowcard' || key == 'redcard') {
      return true;
    }
    if (key == 'statuschange') {
      return isMatchTimeStatusNote(row.note);
    }
    if (_hiddenPlayerActionKeys.contains(key)) {
      return false;
    }
    if (_playerActionTimelineKeys.contains(key)) {
      return row.playerId1 != null;
    }
    return false;
  }

  /// Misma regla que [shouldIncludeRow] para mapas de evento (p. ej. detalle del partido).
  static bool shouldIncludeChronologyMap(Map<String, dynamic> event) {
    final key = canonicalMatchEventTypeKey(event['type']);
    if (key == 'formation') return false;
    if (key == 'substitution') {
      return supabaseInt(event['minute']) != null &&
          supabaseInt(event['minute'])! > 0 &&
          supabaseInt(event['player_id1']) != null &&
          supabaseInt(event['player_id2']) != null;
    }
    if (key == 'scoregoal' || key == 'concedegoal' || key == 'owngoal') {
      return true;
    }
    if (key == 'yellowcard' || key == 'redcard') {
      return true;
    }
    if (key == 'statuschange') {
      return isMatchTimeStatusNote(event['note'] as String?);
    }
    if (_hiddenPlayerActionKeys.contains(key)) {
      return false;
    }
    if (_playerActionTimelineKeys.contains(key)) {
      return supabaseInt(event['player_id1']) != null;
    }
    return false;
  }

  static DateTime? resolveSecondHalfStart(List<MatchLiveTimelineRow> rows) {
    DateTime? best;
    for (final r in rows) {
      if (canonicalMatchEventTypeKey(r.rawType) != 'statuschange') continue;
      final note = r.note?.trim();
      if (!noteIndicatesSecondHalfKickoff(note)) continue;
      final t = r.createdAt;
      if (best == null || t.isAfter(best)) {
        best = t;
      }
    }
    return best;
  }

  static int eventHalf(MatchLiveTimelineRow row, DateTime? secondHalfStart) {
    if (secondHalfStart == null) return 1;
    return !row.createdAt.isBefore(secondHalfStart) ? 2 : 1;
  }

  static int compareDisplayOrder(
    MatchLiveTimelineRow a,
    MatchLiveTimelineRow b,
    DateTime? secondHalfStart,
  ) {
    final ha = eventHalf(a, secondHalfStart);
    final hb = eventHalf(b, secondHalfStart);
    if (ha != hb) {
      return hb.compareTo(ha);
    }
    final ma = a.minute;
    final mb = b.minute;
    if (ma != mb) {
      return mb.compareTo(ma);
    }
    final byTime = b.createdAt.compareTo(a.createdAt);
    if (byTime != 0) return byTime;
    return b.id.compareTo(a.id);
  }

  static List<MatchLiveTimelineRow> filterAndSort(
    List<MatchLiveTimelineRow> source,
  ) {
    final filtered = source.where(shouldIncludeRow).toList();
    final t2h = resolveSecondHalfStart(filtered);
    filtered.sort((a, b) => compareDisplayOrder(a, b, t2h));
    return filtered;
  }
}
