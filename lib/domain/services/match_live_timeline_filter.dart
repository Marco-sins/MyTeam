import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/domain/entities/match_live_timeline_row.dart';

/// Filtra y ordena eventos para la lista en vivo (dominio, sin Supabase).
class MatchLiveTimelineFilter {
  MatchLiveTimelineFilter._();

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

  /// [isExternalSpectator]: vista reducida (como el detalle del partido para
  /// externos). Si es `false` (entrenador/admin), se muestran todos los
  /// eventos de juego salvo formaciones.
  static bool shouldIncludeRow(
    MatchLiveTimelineRow row, {
    required bool isExternalSpectator,
  }) {
    final key = canonicalMatchEventTypeKey(row.rawType);
    if (key == 'formation') return false;
    if (key == 'substitution') {
      return row.playerId2 != null;
    }

    if (!isExternalSpectator) {
      return true;
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

  static int eventHalf(
    MatchLiveTimelineRow row,
    DateTime? secondHalfStart,
  ) {
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
    List<MatchLiveTimelineRow> source, {
    required bool isExternalSpectator,
  }) {
    final filtered = source
        .where(
          (r) => shouldIncludeRow(
            r,
            isExternalSpectator: isExternalSpectator,
          ),
        )
        .toList();
    final t2h = resolveSecondHalfStart(filtered);
    filtered.sort((a, b) => compareDisplayOrder(a, b, t2h));
    return filtered;
  }
}
