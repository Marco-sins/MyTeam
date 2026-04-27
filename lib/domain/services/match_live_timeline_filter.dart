import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/domain/entities/match_live_timeline_row.dart';

/// Filtra y ordena eventos para la lista en vivo (dominio, sin Supabase).
class MatchLiveTimelineFilter {
  MatchLiveTimelineFilter._();

  /// Acciones de jugador que **sí** entran en la cronología (además de goles,
  /// sustituciones, tarjetas y cambios de periodo).
  ///
  /// No se listan: buena parada ([goodsave]), cantada ([cantada]), mal pase
  /// ([badpass]), córners / contadores manuales, ni tiro / recuperación / pases
  /// / jugadas; solo falta entre acciones de campo.
  static const Set<String> _playerActionTimelineKeys = {
    'foul',
  };

  static const Set<String> _hiddenPlayerActionKeys = {
    'goodsave',
    'cantada',
    'badpass',
  };

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

  static bool _isPrematchInNote(String? note) {
    if (note == null || note.isEmpty) return false;
    return note.toLowerCase().contains('prematch');
  }

  /// Inicio de la 1.ª parte (nota del [statusChange] en el gestor).
  static bool isFirstHalfKickoffStatusNote(String? note) {
    if (note == null) return false;
    final lower = note.trim().toLowerCase();
    return lower == 'inicio 1ª parte' || lower == 'inicio 1a parte';
  }

  /// [null] si en el lote no hay "Inicio 1ª parte".
  static DateTime? resolveFirstHalfKickoff(Iterable<MatchLiveTimelineRow> rows) {
    DateTime? best;
    for (final r in rows) {
      if (canonicalMatchEventTypeKey(r.rawType) != 'statuschange') continue;
      if (!isFirstHalfKickoffStatusNote(r.note)) continue;
      final t = r.createdAt;
      if (best == null || t.isBefore(best)) {
        best = t;
      }
    }
    return best;
  }

  static DateTime? resolveFirstHalfKickoffFromEventMaps(
    Iterable<Map<String, dynamic>> maps,
  ) {
    final rows = maps.map(
      (m) => MatchLiveTimelineRow.fromPostgresMap(
        Map<String, dynamic>.from(m),
      ),
    );
    return resolveFirstHalfKickoff(rows);
  }

  /// Sustituciones de alineación antes del pitido inicial (no "partido" en curso).
  static bool isBeforeMatchChronologySubstitution(
    MatchLiveTimelineRow r,
    DateTime? firstHalfKickoff,
  ) {
    if (canonicalMatchEventTypeKey(r.rawType) != 'substitution') {
      return false;
    }
    if (_isPrematchInNote(r.note)) return true;
    if (firstHalfKickoff != null) {
      return r.createdAt.isBefore(firstHalfKickoff);
    }
    if (r.minute == 0) return true;
    return false;
  }

  /// Tipo y categoría: misma lógica que la lista "visible" (sin excluir prematch).
  static bool _shouldIncludeRowByType(MatchLiveTimelineRow row) {
    final key = canonicalMatchEventTypeKey(row.rawType);
    if (key == 'formation') return false;
    if (key == 'substitution') {
      return row.playerId1 != null;
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

  static bool _shouldIncludeChronologyMapByType(Map<String, dynamic> event) {
    final key = canonicalMatchEventTypeKey(event['type']);
    if (key == 'formation') return false;
    if (key == 'substitution') {
      return supabaseInt(event['player_id1']) != null;
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

  static bool shouldIncludeChronologyMap(
    Map<String, dynamic> event, {
    required DateTime? firstHalfKickoff,
  }) {
    if (!_shouldIncludeChronologyMapByType(event)) return false;
    final r = MatchLiveTimelineRow.fromPostgresMap(
      Map<String, dynamic>.from(event),
    );
    if (isBeforeMatchChronologySubstitution(r, firstHalfKickoff)) return false;
    return true;
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

  static int eventHalf(
    MatchLiveTimelineRow row,
    DateTime? secondHalfStart,
  ) {
    if (secondHalfStart == null) return 1;
    return !row.createdAt.isBefore(secondHalfStart) ? 2 : 1;
  }

  static int _minuteForChronologySort(MatchLiveTimelineRow r) {
    return r.minute;
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
    final ma = _minuteForChronologySort(a);
    final mb = _minuteForChronologySort(b);
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
    final kick1 = resolveFirstHalfKickoff(source);
    final filtered = source
        .where(
          (r) =>
              _shouldIncludeRowByType(r) &&
              !isBeforeMatchChronologySubstitution(r, kick1),
        )
        .toList();
    final t2h = resolveSecondHalfStart(filtered);
    filtered.sort((a, b) => compareDisplayOrder(a, b, t2h));
    return filtered;
  }
}
