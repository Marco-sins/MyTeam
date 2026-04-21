import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/match_event.dart';

/// Orden estable: minuto y, a igualdad, id del evento.
void sortMatchEventsByTime(List<MatchEvent> events) {
  events.sort((a, b) {
    if (a.minute != b.minute) {
      return a.minute.compareTo(b.minute);
    }
    return a.id.compareTo(b.id);
  });
}

int matchEndMinuteFromEvents(List<MatchEvent> events) {
  int? finishedMinute;
  for (final e in events) {
    if (e.type == MatchEventEnum.statusChange &&
        e.note != null &&
        e.note!.toLowerCase().contains('final')) {
      finishedMinute = e.minute;
    }
  }
  if (finishedMinute != null) {
    return finishedMinute;
  }
  int maxMinute = 0;
  for (final e in events) {
    if (e.minute > maxMinute) {
      maxMinute = e.minute;
    }
  }
  if (maxMinute > 0) {
    return maxMinute;
  }
  return 70;
}

/// Misma lógica que en la pantalla de estadísticas del partido: titulares,
/// sustituciones y minuto de fin reconstruyen los minutos disputados.
///
/// Si [overrideMatchEndMinute] no es null, se usa como minuto tope (p. ej. el
/// minuto actual del cronómetro en el gestor en vivo). Si es null, se deduce
/// del partido terminado o del último evento ([matchEndMinuteFromEvents]).
int minutesPlayedForPlayer({
  required List<MatchEvent> events,
  required int playerId,
  required bool isStarter,
  int? overrideMatchEndMinute,
}) {
  final sorted = List<MatchEvent>.from(events);
  sortMatchEventsByTime(sorted);

  final int matchEndMinute =
      overrideMatchEndMinute ?? matchEndMinuteFromEvents(sorted);
  if (matchEndMinute <= 0) {
    return 0;
  }

  bool onField = isStarter;
  int lastOnMinute = isStarter ? 0 : -1;
  int totalMinutes = 0;

  for (final event in sorted) {
    if (event.type != MatchEventEnum.substitution) {
      continue;
    }

    final minute = event.minute;
    final int? inId = event.playerId1;
    final int? outId = event.playerId2;

    if (outId == playerId && onField) {
      final start = lastOnMinute >= 0 ? lastOnMinute : minute;
      if (minute > start) {
        totalMinutes += minute - start;
      }
      onField = false;
      lastOnMinute = -1;
    } else if (inId == playerId && !onField) {
      onField = true;
      lastOnMinute = minute;
    }
  }

  if (onField) {
    final start = lastOnMinute >= 0 ? lastOnMinute : 0;
    if (matchEndMinute > start) {
      totalMinutes += matchEndMinute - start;
    }
  }

  if (totalMinutes < 0) {
    return 0;
  }
  return totalMinutes;
}
