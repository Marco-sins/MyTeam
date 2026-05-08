import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/match_event.dart';

/// Extrae el tiempo total de un minuto que incluye tiempo de descuento.
/// Ejemplo: Si el minuto es 47 y regulatoriamente es 45 minutos (senior),
/// el tiempo de descuento es 2 minutos. Pero para calcular minutos jugados,
/// simplemente usamos el valor de minute como está.
///
/// Si la entrada es un minuto como "45", devuelve 45.
/// Si es un minuto en segundapart con descuento ya sumado (ej. 47 para 45+2),
/// devuelve 47 tal cual.
int getTotalMatchMinutesIncludingStoppage(int minute) {
  // El minute recibido ya incluye el tiempo de descuento si el reloj ha pasado
  // la duración reglamentaria. Simplemente devolvemos el valor tal cual.
  return minute;
}

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
  int yellowCount = 0;
  bool sentOff = false;

  for (final event in sorted) {
    final minute = event.minute;

    if (event.type == MatchEventEnum.yellowCard &&
        event.playerId1 == playerId) {
      yellowCount++;
      if (yellowCount >= 2 && onField) {
        final start = lastOnMinute >= 0 ? lastOnMinute : minute;
        if (minute > start) {
          totalMinutes += minute - start;
        }
        onField = false;
        lastOnMinute = -1;
        sentOff = true;
      }
      continue;
    }

    if (event.type == MatchEventEnum.redCard && event.playerId1 == playerId) {
      if (onField) {
        final start = lastOnMinute >= 0 ? lastOnMinute : minute;
        if (minute > start) {
          totalMinutes += minute - start;
        }
        onField = false;
        lastOnMinute = -1;
      }
      sentOff = true;
      continue;
    }

    if (sentOff) {
      continue;
    }

    if (event.type != MatchEventEnum.substitution) {
      continue;
    }

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
