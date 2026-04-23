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
/// sustituciones, [yellowCard] (doble = expulsión) y [redCard] determinan
/// presencia en campo. Tras la expulsión dejan de contarse minutos, como si
/// no estuviera jugando.
///
/// Si [overrideMatchEndMinute] no es null, se usa como minuto tope (p. ej. el
/// minuto actual del cronómetro en el gestor en vivo). Si es null, se deduce
/// del partido terminado o del último evento ([matchEndMinuteFromEvents]).
///
/// [preSorted] en true: no se reordena (el orden debe ser cronológico, p. ej.
/// misma vinculación `minute`+`created_at` que en estadísticas en vivo).
int minutesPlayedForPlayer({
  required List<MatchEvent> events,
  required int playerId,
  required bool isStarter,
  int? overrideMatchEndMinute,
  bool preSorted = false,
}) {
  final List<MatchEvent> sorted = List<MatchEvent>.from(events);
  if (!preSorted) {
    sortMatchEventsByTime(sorted);
  }

  final int matchEndMinute =
      overrideMatchEndMinute ?? matchEndMinuteFromEvents(sorted);
  if (matchEndMinute <= 0) {
    return 0;
  }

  bool onField = isStarter;
  int lastOnMinute = isStarter ? 0 : -1;
  int totalMinutes = 0;
  int yellowsForPlayer = 0;
  var sentOffPermanently = false;

  void leaveFieldAtMinute(int minute) {
    if (!onField) {
      return;
    }
    final int start = lastOnMinute >= 0 ? lastOnMinute : minute;
    if (minute > start) {
      totalMinutes += minute - start;
    }
    onField = false;
    lastOnMinute = -1;
  }

  for (final event in sorted) {
    final minute = event.minute;
    final int? inId = event.playerId1;
    final int? outId = event.playerId2;

    switch (event.type) {
      case MatchEventEnum.substitution:
        if (outId == playerId && onField) {
          leaveFieldAtMinute(minute);
        } else if (inId == playerId && !onField && !sentOffPermanently) {
          onField = true;
          lastOnMinute = minute;
        }
        break;
      case MatchEventEnum.yellowCard:
        if (inId == playerId) {
          yellowsForPlayer += 1;
          if (yellowsForPlayer >= 2) {
            leaveFieldAtMinute(minute);
            sentOffPermanently = true;
          }
        }
        break;
      case MatchEventEnum.redCard:
        if (inId == playerId) {
          leaveFieldAtMinute(minute);
          sentOffPermanently = true;
        }
        break;
      default:
        break;
    }
  }

  if (onField) {
    final int start = lastOnMinute >= 0 ? lastOnMinute : 0;
    if (matchEndMinute > start) {
      totalMinutes += matchEndMinute - start;
    }
  }

  if (totalMinutes < 0) {
    return 0;
  }
  return totalMinutes;
}
