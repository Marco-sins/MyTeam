import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/domain/entities/team_scoring_config.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';

/// Conteos por tipo de evento, misma lógica que [calculatePlayerRating]
/// (tipos canónicos + notas legacy en [player_rating_utils]).
class PlayerMatchEventCounts {
  const PlayerMatchEventCounts({
    this.goals = 0,
    this.assists = 0,
    this.ownGoals = 0,
    this.goalsConceded = 0,
    this.shots = 0,
    this.saves = 0,
    this.keyPasses = 0,
    this.goodPasses = 0,
    this.badPasses = 0,
    this.goodPlays = 0,
    this.badPlays = 0,
    this.ballRecoveries = 0,
    this.fouls = 0,
    this.cantadas = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });

  final int goals;
  final int assists;
  final int ownGoals;
  final int goalsConceded;
  final int shots;
  final int saves;
  final int keyPasses;
  final int goodPasses;
  final int badPasses;
  final int goodPlays;
  final int badPlays;
  final int ballRecoveries;
  final int fouls;
  final int cantadas;
  final int yellowCards;
  final int redCards;

  bool get hasAnyVisibleStat {
    return goals + assists + ownGoals + goalsConceded + shots + saves + keyPasses + goodPasses + badPasses + goodPlays + badPlays + ballRecoveries + fouls + cantadas + yellowCards + redCards > 0;
  }
}

/// Cuenta eventos de un jugador; usar la lista **completa** de [match_events]
/// (p. ej. [MatchStatsState.allEventMaps]), no el listado filtrado de cronología.
PlayerMatchEventCounts countPlayerMatchEventStats(
  int playerId,
  List<Map<String, dynamic>> events,
) {
  int goals = 0;
  int assists = 0;
  int ownGoals = 0;
  int goalsConceded = 0;
  int shots = 0;
  int saves = 0;
  int keyPasses = 0;
  int goodPasses = 0;
  int badPasses = 0;
  int goodPlays = 0;
  int badPlays = 0;
  int ballRecoveries = 0;
  int fouls = 0;
  int cantadas = 0;
  int yellowCards = 0;
  int redCards = 0;

  for (final event in events) {
    final rawType = event['type'];
    if (rawType == null) continue;

    final typeKey = canonicalMatchEventTypeKey(rawType);
    final int? p1 = event['player_id1'] as int?;
    final int? p2 = event['player_id2'] as int?;
    final String? noteRaw = event['note'] as String?;
    final String? note = noteRaw?.trim();
    final String noteLower = note?.toLowerCase() ?? '';

    if (typeKey == 'scoregoal') {
      if (p1 == playerId) {
        goals++;
      }
      if (p2 == playerId) {
        assists++;
      }
      continue;
    }

    if (p1 != playerId) {
      continue;
    }

    if (typeKey == 'owngoal' ||
        noteLower == 'gol en propia' ||
        noteLower == 'autogol') {
      ownGoals++;
      continue;
    }

    if (typeKey == 'concedegoal' || noteLower == 'gol concedido') {
      goalsConceded++;
      continue;
    }

    switch (typeKey) {
      case 'shot':
        shots++;
        continue;
      case 'goodpass':
        goodPasses++;
        continue;
      case 'badpass':
        badPasses++;
        continue;
      case 'goodplay':
        goodPlays++;
        continue;
      case 'badplay':
        badPlays++;
        continue;
      case 'ballrecovery':
        ballRecoveries++;
        continue;
      case 'goodsave':
        saves++;
        continue;
      case 'yellowcard':
        yellowCards++;
        continue;
      case 'redcard':
        redCards++;
        continue;
      case 'foul':
        fouls++;
        continue;
      case 'cantada':
        cantadas++;
        continue;
      case 'keypass':
        keyPasses++;
        continue;
      default:
        break;
    }

    if (noteLower == 'buen pase' || noteLower == 'pase clave') {
      if (noteLower == 'pase clave') {
        keyPasses++;
      } else {
        goodPasses++;
      }
      continue;
    }
    if (noteLower == 'mal pase' || noteLower == 'pase impreciso') {
      badPasses++;
      continue;
    }
    if (noteLower == 'buena jugada' || noteLower == 'jugada clave') {
      goodPlays++;
      continue;
    }
    if (noteLower == 'mala jugada' || noteLower == 'jugada imprecisa') {
      badPlays++;
      continue;
    }
    if (noteLower == 'balón recuperado' || noteLower == 'balon recuperado') {
      ballRecoveries++;
      continue;
    }
    if (noteLower == 'buena parada' ||
        noteLower.contains('increíble parada') ||
        noteLower.contains('increible parada')) {
      saves++;
      continue;
    }
    if (noteLower == 'tiro') {
      shots++;
      continue;
    }
    if (noteLower == 'falta') {
      fouls++;
      continue;
    }
    if (noteLower == 'tarjeta amarilla') {
      yellowCards++;
      continue;
    }
    if (noteLower == 'tarjeta roja') {
      redCards++;
      continue;
    }
    if (noteLower == 'cantada') {
      cantadas++;
      continue;
    }
  }

  return PlayerMatchEventCounts(
    goals: goals,
    assists: assists,
    ownGoals: ownGoals,
    goalsConceded: goalsConceded,
    shots: shots,
    saves: saves,
    keyPasses: keyPasses,
    goodPasses: goodPasses,
    badPasses: badPasses,
    goodPlays: goodPlays,
    badPlays: badPlays,
    ballRecoveries: ballRecoveries,
    fouls: fouls,
    cantadas: cantadas,
    yellowCards: yellowCards,
    redCards: redCards,
  );
}

/// Conteos por id de fila de valoración del equipo (alineado con [scoringLineIdForPlayerEvent]).
Map<String, int> countPlayerEventsByScoringLine(
  int playerId,
  List<Map<String, dynamic>> events, {
  TeamScoringConfig? teamScoring,
}) {
  final out = <String, int>{};
  for (final e in events) {
    final id = scoringLineIdForPlayerEvent(
      playerId,
      e,
      teamScoring: teamScoring,
    );
    if (id != null) {
      out[id] = (out[id] ?? 0) + 1;
    }
  }
  return out;
}
