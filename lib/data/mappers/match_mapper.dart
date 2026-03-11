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
      status: match.status,
      lineups: match.lineups,
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
      status: matchModel.status,
      lineups: matchModel.lineups,
    );
  }
}
