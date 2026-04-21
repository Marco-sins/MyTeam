import 'package:football_manager/core/utils/supabase_dynamic.dart';

/// Calcula la media de un jugador a partir de la lista de eventos del partido.
///
/// - Todos los jugadores empiezan con 5.0 de media.
/// - El resultado se limita al rango [0, 10].
///
/// Eventos actuales (tipo canónico y notas equivalentes):
/// - Gol, buen/mal pase, buena/mala jugada, buena parada, tiro, recuperación,
///   amarilla, roja, falta, cantada.
double calculatePlayerRating(
  int playerId,
  List<Map<String, dynamic>> events, {
  double baseRating = 5.0,
}) {
  double rating = baseRating;

  for (final event in events) {
    final rawType = event['type'];
    if (rawType == null) continue;

    final typeKey = canonicalMatchEventTypeKey(rawType);
    final int? p1 = event['player_id1'] as int?;
    final int? p2 = event['player_id2'] as int?;
    final String? noteRaw = event['note'] as String?;
    final String? note = noteRaw?.trim();
    final String noteLower = note?.toLowerCase() ?? '';

    // Goles (goleador y asistente)
    if (typeKey == 'scoregoal') {
      if (p1 == playerId) {
        rating += 1.0;
      }
      if (p2 == playerId) {
        rating += 0.75;
      }
      continue;
    }

    // A partir de aquí sólo aplicamos notas al jugador principal (player_id1).
    if (p1 != playerId) {
      continue;
    }

    // Gol en propia / autogol
    if (typeKey == 'owngoal' ||
        noteLower == 'gol en propia' ||
        noteLower == 'autogol') {
      rating -= 1.0;
      continue;
    }

    // Gol concedido (portero/defensa)
    if (typeKey == 'concedegoal' || noteLower == 'gol concedido') {
      rating -= 0.4;
      continue;
    }

    switch (typeKey) {
      case 'shot':
        rating += 0.1;
        continue;
      case 'goodpass':
        rating += 0.12;
        continue;
      case 'badpass':
        rating -= 0.12;
        continue;
      case 'goodplay':
        rating += 0.22;
        continue;
      case 'badplay':
        rating -= 0.28;
        continue;
      case 'ballrecovery':
        rating += 0.28;
        continue;
      case 'goodsave':
        rating += 0.42;
        continue;
      case 'yellowcard':
        rating -= 0.9;
        continue;
      case 'redcard':
        rating -= 2.5;
        continue;
      case 'foul':
        rating -= 0.32;
        continue;
      case 'cantada':
        rating -= 1.25;
        continue;
      case 'keypass':
        rating += 0.25;
        continue;
      default:
        break;
    }

    // Compatibilidad con datos antiguos (solo nota / tipos legacy)
    if (noteLower == 'buen pase' || noteLower == 'pase clave') {
      rating += noteLower == 'pase clave' ? 0.25 : 0.12;
      continue;
    }
    if (noteLower == 'mal pase' ||
        noteLower == 'pase impreciso') {
      rating -= 0.12;
      continue;
    }
    if (noteLower == 'buena jugada' || noteLower == 'jugada clave') {
      rating += noteLower == 'jugada clave' ? 0.35 : 0.22;
      continue;
    }
    if (noteLower == 'mala jugada' || noteLower == 'jugada imprecisa') {
      rating -= 0.28;
      continue;
    }
    if (noteLower == 'balón recuperado' || noteLower == 'balon recuperado') {
      rating += 0.28;
      continue;
    }
    if (noteLower == 'buena parada' ||
        noteLower.contains('increíble parada') ||
        noteLower.contains('increible parada')) {
      rating += noteLower.contains('incre') ? 0.55 : 0.42;
      continue;
    }
    if (noteLower == 'tiro') {
      rating += 0.1;
      continue;
    }
    if (noteLower == 'falta') {
      rating -= 0.32;
      continue;
    }
    if (noteLower == 'tarjeta amarilla') {
      rating -= 0.9;
      continue;
    }
    if (noteLower == 'tarjeta roja') {
      rating -= 2.5;
      continue;
    }
    if (noteLower == 'cantada') {
      rating -= 1.25;
      continue;
    }
  }

  if (rating < 0) {
    rating = 0;
  } else if (rating > 10) {
    rating = 10;
  }

  return rating;
}
