import 'package:tfg1/data/mappers/match_lineup_mapper.dart';
import 'package:tfg1/data/models/match_model.dart';
import 'package:tfg1/domain/entities/match.dart';

class MatchMapper {
  static MatchModel toModel(Match match) {
    return MatchModel(
      id: match.id,
      teamId: match.teamId,
      opponent: match.opponent,
      goalsScored: match.goalsScored,
      goalsConceded: match.goalsConceded,
      date: match.date,
      hour: match.hour,
      status: match.status,
      // Convertimos cada alineación de dominio a su modelo
      lineups: match.lineups
          .map((lineup) => MatchLineupMapper.toModel(lineup))
          .toList(),
    );
  }

  static Match toEntity(MatchModel matchModel) {
    return Match(
      id: matchModel.id,
      teamId: matchModel.teamId,
      opponent: matchModel.opponent,
      goalsScored: matchModel.goalsScored,
      goalsConceded: matchModel.goalsConceded,
      date: matchModel.date,
      hour: matchModel.hour,
      status: matchModel.status,
      lineups: matchModel.lineups,
    );
  }
}
