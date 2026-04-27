import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/domain/entities/team_scoring_config.dart';

/// Identificador de fila de valoración ([TeamScoringBuiltinId] o `custom_*`) que
/// aplica a [playerId] para este evento, o null.
///
/// Misma regla que la valoración: un evento solo cuenta en una fila.
String? scoringLineIdForPlayerEvent(
  int playerId,
  Map<String, dynamic> event, {
  TeamScoringConfig? teamScoring,
}) {
  final rawType = event['type'];
  if (rawType == null) {
    return null;
  }

  final typeKey = canonicalMatchEventTypeKey(rawType);
  final int? p1 = event['player_id1'] as int?;
  final int? p2 = event['player_id2'] as int?;
  final String? noteRaw = event['note'] as String?;
  final String? note = noteRaw?.trim();
  final String noteLower = note?.toLowerCase() ?? '';

  if (typeKey == 'scoregoal') {
    if (p1 == playerId) {
      return TeamScoringBuiltinId.scoregoalScorer;
    }
    if (p2 == playerId) {
      return TeamScoringBuiltinId.scoregoalAssist;
    }
    return null;
  }

  if (p1 != playerId) {
    return null;
  }

  if (typeKey == 'owngoal' ||
      noteLower == 'gol en propia' ||
      noteLower == 'autogol') {
    return TeamScoringBuiltinId.owngoal;
  }

  if (typeKey == 'concedegoal' || noteLower == 'gol concedido') {
    return TeamScoringBuiltinId.concedegoal;
  }

  switch (typeKey) {
    case 'shot':
      return TeamScoringBuiltinId.shot;
    case 'goodpass':
      return TeamScoringBuiltinId.goodpass;
    case 'badpass':
      return TeamScoringBuiltinId.badpass;
    case 'goodplay':
      return TeamScoringBuiltinId.goodplay;
    case 'badplay':
      return TeamScoringBuiltinId.badplay;
    case 'ballrecovery':
      return TeamScoringBuiltinId.ballrecovery;
    case 'goodsave':
      return TeamScoringBuiltinId.goodsave;
    case 'yellowcard':
      return TeamScoringBuiltinId.yellowcard;
    case 'redcard':
      return TeamScoringBuiltinId.redcard;
    case 'foul':
      return TeamScoringBuiltinId.foul;
    case 'cantada':
      return TeamScoringBuiltinId.cantada;
    case 'keypass':
      return TeamScoringBuiltinId.keypass;
    default:
      break;
  }

  if (noteLower == 'buen pase' || noteLower == 'pase clave') {
    return noteLower == 'pase clave'
        ? TeamScoringBuiltinId.paseClave
        : TeamScoringBuiltinId.goodpass;
  }
  if (noteLower == 'mal pase' || noteLower == 'pase impreciso') {
    return TeamScoringBuiltinId.badpass;
  }
  if (noteLower == 'buena jugada' || noteLower == 'jugada clave') {
    return noteLower == 'jugada clave'
        ? TeamScoringBuiltinId.jugadaClave
        : TeamScoringBuiltinId.goodplay;
  }
  if (noteLower == 'mala jugada' || noteLower == 'jugada imprecisa') {
    return TeamScoringBuiltinId.badplay;
  }
  if (noteLower == 'balón recuperado' || noteLower == 'balon recuperado') {
    return TeamScoringBuiltinId.ballrecovery;
  }
  if (noteLower == 'buena parada' ||
      noteLower.contains('increíble parada') ||
      noteLower.contains('increible parada')) {
    return noteLower.contains('incre')
        ? TeamScoringBuiltinId.goodsaveIncredible
        : TeamScoringBuiltinId.goodsave;
  }
  if (noteLower == 'tiro') {
    return TeamScoringBuiltinId.tiroNote;
  }
  if (noteLower == 'falta') {
    return TeamScoringBuiltinId.foul;
  }
  if (noteLower == 'tarjeta amarilla') {
    return TeamScoringBuiltinId.tarjetaAmarilla;
  }
  if (noteLower == 'tarjeta roja') {
    return TeamScoringBuiltinId.tarjetaRoja;
  }
  if (noteLower == 'cantada') {
    return TeamScoringBuiltinId.cantadaNote;
  }

  if (teamScoring != null) {
    for (final line in teamScoring.customLines) {
      final n = line.name;
      if (n == null || n.trim().isEmpty) {
        continue;
      }
      if (noteLower == n.toLowerCase().trim()) {
        return line.id;
      }
    }
  }
  return null;
}

/// Calcula la media de un jugador a partir de la lista de eventos del partido.
///
/// - Todos los jugadores empiezan con 5.0 de media.
/// - El resultado se limita al rango [0, 10].
/// - [teamScoring] opcional: pesos por equipo (gestión de equipo). Si es null,
///   se usan los pesos por defecto de [TeamScoringConfig.defaultWeightMap].
double calculatePlayerRating(
  int playerId,
  List<Map<String, dynamic>> events, {
  double baseRating = 5.0,
  TeamScoringConfig? teamScoring,
}) {
  var rating = baseRating;
  for (final event in events) {
    final id = scoringLineIdForPlayerEvent(
      playerId,
      event,
      teamScoring: teamScoring,
    );
    if (id == null) {
      continue;
    }
    double delta;
    if (teamScoring == null) {
      if (id.startsWith(TeamScoringBuiltinId.prefixCustom)) {
        continue;
      }
      delta = TeamScoringConfig.defaultWeightFor(id);
    } else {
      delta = teamScoring.weightFor(id);
    }
    rating += delta;
  }

  if (rating < 0) {
    rating = 0;
  } else if (rating > 10) {
    rating = 10;
  }

  return rating;
}
