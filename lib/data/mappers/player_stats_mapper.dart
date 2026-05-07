/// Mapeador para `player_stats` entre filas de BD y objetos de dominio.
import 'package:football_manager/data/models/player_stats_model.dart';
import 'package:football_manager/domain/entities/player_stats.dart';

class PlayerStatsMapper {
  static PlayerStatsModel toModel(PlayerStats playerStats) {
    return PlayerStatsModel(
      id: playerStats.id,
      playerId: playerStats.playerId,
      goals: playerStats.goals,
      assists: playerStats.assists,
      yellowCards: playerStats.yellowCards,
      redCards: playerStats.redCards,
      matchesPlayed: playerStats.matchesPlayed,
      minutesPlayed: playerStats.minutesPlayed,
      timesStarted: playerStats.timesStarted,
    );
  }

  static PlayerStats toEntity(PlayerStatsModel playerStatsModel) {
    return PlayerStats(
      id: playerStatsModel.id,
      playerId: playerStatsModel.playerId,
      goals: playerStatsModel.goals,
      assists: playerStatsModel.assists,
      yellowCards: playerStatsModel.yellowCards,
      redCards: playerStatsModel.redCards,
      matchesPlayed: playerStatsModel.matchesPlayed,
      minutesPlayed: playerStatsModel.minutesPlayed,
      timesStarted: playerStatsModel.timesStarted,
    );
  }
}
