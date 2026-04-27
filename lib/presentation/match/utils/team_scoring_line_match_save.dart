import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/team_scoring_config.dart';

/// Qué persistir según la fila elegida (sin textos de UI).
sealed class MatchPlayerScoringSaveKind {
  const MatchPlayerScoringSaveKind();
}

/// Flujo de gol con posible asistente.
final class MatchPlayerScoringSaveGoal extends MatchPlayerScoringSaveKind {
  const MatchPlayerScoringSaveGoal();
}

/// Evento con tipo y nota (alineado con [calculatePlayerRating]).
final class MatchPlayerScoringSaveEvent extends MatchPlayerScoringSaveKind {
  const MatchPlayerScoringSaveEvent({
    required this.type,
    required this.note,
  });

  final MatchEventEnum type;
  final String note;
}

/// Selección completa para confirmar y guardar.
class MatchPlayerScoringSelection {
  const MatchPlayerScoringSelection({
    required this.confirmLabel,
    required this.kind,
  });

  final String confirmLabel;
  final MatchPlayerScoringSaveKind kind;
}

/// Ajusta la lista para un solo botón "Gol" cuando hay goleador y asistencia.
List<TeamScoringLine> scoringLinesForPlayerActionList(
  List<TeamScoringLine> lines,
) {
  final hasScorer = lines
      .any((l) => l.id == TeamScoringBuiltinId.scoregoalScorer);
  final hasAssist = lines
      .any((l) => l.id == TeamScoringBuiltinId.scoregoalAssist);
  if (hasScorer && hasAssist) {
    return [
      for (final l in lines)
        if (l.id != TeamScoringBuiltinId.scoregoalAssist) l,
    ];
  }
  if (!hasScorer && hasAssist) {
    return [
      for (final l in lines)
        if (l.id == TeamScoringBuiltinId.scoregoalAssist)
          TeamScoringLine(
            id: TeamScoringBuiltinId.scoregoalScorer,
            points: l.points,
            name: l.name,
          )
        else
          l,
    ];
  }
  return lines;
}

/// Ordena para el modal de acción: primero filas con peso no negativo (verde),
/// luego las negativas (rojo). Dentro de cada bloque: más impacto arriba.
List<TeamScoringLine> sortedScoringLinesForPlayerModal(
  List<TeamScoringLine> lines,
) {
  final copy = List<TeamScoringLine>.from(lines);
  copy.sort((a, b) {
    final aNonNeg = a.points >= 0;
    final bNonNeg = b.points >= 0;
    if (aNonNeg != bNonNeg) {
      return aNonNeg ? -1 : 1;
    }
    if (aNonNeg) {
      final c = b.points.compareTo(a.points);
      if (c != 0) {
        return c;
      }
    } else {
      final c = a.points.compareTo(b.points);
      if (c != 0) {
        return c;
      }
    }
    return a.id.compareTo(b.id);
  });
  return copy;
}

/// `null` si la fila no se puede registrar (p. ej. custom sin nombre).
MatchPlayerScoringSaveKind? teamScoringLineToSaveKind(TeamScoringLine line) {
  if (line.isCustom) {
    final n = line.name?.trim() ?? '';
    if (n.isEmpty) {
      return null;
    }
    return MatchPlayerScoringSaveEvent(
      type: MatchEventEnum.penalty,
      note: n,
    );
  }
  return _builtinSaveKind(line.id);
}

MatchPlayerScoringSaveKind? _builtinSaveKind(String id) {
  switch (id) {
    case TeamScoringBuiltinId.scoregoalScorer:
    case TeamScoringBuiltinId.scoregoalAssist:
      return const MatchPlayerScoringSaveGoal();

    case TeamScoringBuiltinId.owngoal:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.ownGoal,
        note: 'Gol en propia',
      );
    case TeamScoringBuiltinId.concedegoal:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.concedeGoal,
        note: 'Gol concedido',
      );
    case TeamScoringBuiltinId.shot:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.shot,
        note: 'Tiro',
      );
    case TeamScoringBuiltinId.goodpass:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.goodPass,
        note: 'Buen pase',
      );
    case TeamScoringBuiltinId.badpass:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.badPass,
        note: 'Mal pase',
      );
    case TeamScoringBuiltinId.goodplay:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.goodPlay,
        note: 'Buena jugada',
      );
    case TeamScoringBuiltinId.badplay:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.badPlay,
        note: 'Mala jugada',
      );
    case TeamScoringBuiltinId.ballrecovery:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.ballRecovery,
        note: 'Balón recuperado',
      );
    case TeamScoringBuiltinId.goodsave:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.goodSave,
        note: 'Buena parada',
      );
    case TeamScoringBuiltinId.goodsaveIncredible:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.goodSave,
        note: 'Increíble parada',
      );
    case TeamScoringBuiltinId.yellowcard:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.yellowCard,
        note: 'Tarjeta amarilla',
      );
    case TeamScoringBuiltinId.redcard:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.redCard,
        note: 'Tarjeta roja',
      );
    case TeamScoringBuiltinId.foul:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.foul,
        note: 'Falta',
      );
    case TeamScoringBuiltinId.cantada:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.cantada,
        note: 'Cantada',
      );
    case TeamScoringBuiltinId.keypass:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.keyPass,
        note: 'Pase clave',
      );
    case TeamScoringBuiltinId.paseClave:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.penalty,
        note: 'pase clave',
      );
    case TeamScoringBuiltinId.jugadaClave:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.penalty,
        note: 'jugada clave',
      );
    case TeamScoringBuiltinId.tiroNote:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.penalty,
        note: 'tiro',
      );
    case TeamScoringBuiltinId.tarjetaAmarilla:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.penalty,
        note: 'tarjeta amarilla',
      );
    case TeamScoringBuiltinId.tarjetaRoja:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.penalty,
        note: 'tarjeta roja',
      );
    case TeamScoringBuiltinId.cantadaNote:
      return const MatchPlayerScoringSaveEvent(
        type: MatchEventEnum.penalty,
        note: 'cantada',
      );
  }
  return null;
}

bool scoringLineUsesNegativeColor(TeamScoringLine line) => line.points < 0;
