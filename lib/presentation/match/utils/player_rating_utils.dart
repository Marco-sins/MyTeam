import 'package:football_manager/core/utils/supabase_dynamic.dart';

/// Calcula la media de un jugador a partir de la lista de eventos del partido.
///
/// - Todos los jugadores empiezan con 5.0 de media.
/// - El resultado se limita al rango [0, 10].
///
/// Los eventos deben tener al menos las claves:
/// - 'type' (String o enum.toString())
/// - 'player_id1' (int?)
/// - 'player_id2' (int?)
/// - 'note' (String?)
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
        rating += 1.0; // gol
      }
      if (p2 == playerId) {
        rating += 0.75; // asistencia
      }
    }

    // A partir de aquí sólo aplicamos notas al jugador principal (player_id1).
    if (p1 != playerId) {
      continue;
    }

    if (typeKey == 'shot') {
      rating += 0.12;
      continue;
    }

    // Gol en propia / autogol
    if (typeKey == 'owngoal' ||
        noteLower == 'gol en propia' ||
        noteLower == 'autogol') {
      rating -= 1.0;
      continue;
    }

    // Gol concedido (a nivel individual, portero/defensa implicado)
    if (typeKey == 'concedegoal' || noteLower == 'gol concedido') {
      rating -= 0.4;
      continue;
    }

    // Tarjetas
    if (typeKey == 'yellowcard' || noteLower == 'tarjeta amarilla') {
      rating -= 1.0;
      continue;
    }

    if (typeKey == 'redcard' || noteLower == 'tarjeta roja') {
      rating -= 3.0;
      continue;
    }

    if (typeKey == 'goodpass') {
      rating += 0.1;
      continue;
    }

    if (typeKey == 'badpass') {
      rating -= 0.1;
      continue;
    }

    if (typeKey == 'goodplay') {
      rating += 0.2;
      continue;
    }

    if (typeKey == 'badplay') {
      rating -= 0.3;
      continue;
    }

    if (typeKey == 'ballrecovery') {
      rating += 0.3;
      continue;
    }

    if (typeKey == 'keypass') {
      rating += 0.3;
      continue;
    }

    if (typeKey == 'goodsave') {
      if (noteLower.contains('increíble') || noteLower.contains('increible')) {
        rating += 0.75;
      } else {
        rating += 0.35;
      }
      continue;
    }

    // Buen pase
    if (noteLower == 'buen pase') {
      rating += 0.1;
      continue;
    }

    // Pase clave
    if (noteLower == 'pase clave') {
      rating += 0.3;
      continue;
    }

    // Buena jugada
    if (noteLower == 'buena jugada') {
      rating += 0.2;
      continue;
    }

    // Jugada clave
    if (noteLower == 'jugada clave') {
      rating += 0.5;
      continue;
    }

    // Gana posesión
    if (noteLower == 'gana posesión' || noteLower == 'gana posesion') {
      rating += 0.3;
      continue;
    }

    // Buena parada
    if (noteLower == 'buena parada') {
      rating += 0.35;
      continue;
    }

    // Increíble parada
    if (noteLower == 'increíble parada' || noteLower == 'increible parada') {
      rating += 0.75;
      continue;
    }

    // Mal pase / pase impreciso
    if (noteLower == 'mal pase' || noteLower == 'pase impreciso') {
      rating -= 0.1;
      continue;
    }

    // Mala jugada / jugada imprecisa
    if (noteLower == 'mala jugada' || noteLower == 'jugada imprecisa') {
      rating -= 0.3;
      continue;
    }

    // Recuperación (solo nota, sin tipo dedicado)
    if (noteLower == 'balón recuperado' || noteLower == 'balon recuperado') {
      rating += 0.3;
      continue;
    }

    // Pierde posesión
    if (noteLower == 'pierde posesión' || noteLower == 'pierde posesion') {
      rating -= 0.2;
      continue;
    }

    // Pierde posición
    if (noteLower == 'pierde posición' || noteLower == 'pierde posicion') {
      rating -= 0.2;
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
