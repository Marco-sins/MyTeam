import 'package:tfg1/data/models/match_lineup_model.dart';
import 'package:tfg1/domain/entities/match_lineup.dart';

class MatchLineupMapper {
  static MatchLineupModel toModel(MatchLineup matchLineup) {
    return MatchLineupModel(
      id: matchLineup.id,
      playerId: matchLineup.playerId,
      matchId: matchLineup.matchId,
      isStarting: matchLineup.isStarting,
      minutesPlayed: matchLineup.minutesPlayed,
      rating: matchLineup.rating,
    );
  }

  static MatchLineup toEntity(MatchLineupModel matchLineupModel) {
    return MatchLineup(
      id: matchLineupModel.id,
      playerId: matchLineupModel.playerId,
      matchId: matchLineupModel.matchId,
      isStarting: matchLineupModel.isStarting,
      minutesPlayed: matchLineupModel.minutesPlayed,
      rating: matchLineupModel.rating,
    );
  }
}