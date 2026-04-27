import 'package:football_manager/data/models/match_lineup_model.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';

class MatchLineupMapper {
  static MatchLineupModel toModel(MatchLineup matchLineup) {
    return MatchLineupModel(
      id: matchLineup.id,
      playerId: matchLineup.playerId,
      matchId: matchLineup.matchId,
      isStarting: matchLineup.isStarting,
      minutesPlayed: matchLineup.minutesPlayed,
      position: matchLineup.position,
      initialPosition: matchLineup.initialPosition,
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
      position: matchLineupModel.position,
      initialPosition: matchLineupModel.initialPosition,
      rating: matchLineupModel.rating,
    );
  }
}
