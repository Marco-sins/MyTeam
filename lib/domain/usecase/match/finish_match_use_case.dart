import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/match_event_enum.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/match_event.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/player_stats.dart';
import 'package:tfg1/domain/i_repositories/i_match_event_repository.dart';
import 'package:tfg1/domain/i_repositories/i_match_repository.dart';
import 'package:tfg1/domain/i_repositories/i_player_repository.dart';

class FinishMatchUseCase {
  final IMatchRepository _matchRepository;
  final IMatchEventRepository _matchEventRepository;
  final IPlayerRepository _playerRepository;

  FinishMatchUseCase(
    this._matchRepository,
    this._matchEventRepository,
    this._playerRepository,
  );

  Future<Either<Failure, void>> call(Match match, AuthUser user) async {
    if (user.teamRoles[match.teamId] != UserRole.admin) {
      return Left(
        PermissionFailure('You do not have permission to finish this match.'),
      );
    }
    Either<Failure, List<MatchEvent>> events = await _matchEventRepository
        .getMatchEventsByMatch(match.id);
    if (events.isLeft()) {
      // If it is an error, return the error
      return events;
    }

    // If it is successful, calculate the goals scored and conceded based on the
    // match events. Cada gol se guarda una sola vez, con playerId1 como
    // goleador y playerId2 como asistente (si la hay).
    final List<MatchEvent> matchEvents = events.getOrElse(() => []);

    int goalsScored = 0;
    int goalsConceded = 0;

    for (int i = 0; i < matchEvents.length; i++) {
      if (matchEvents[i].type == MatchEventEnum.scoreGoal) {
        goalsScored++;
      } else if (matchEvents[i].type == MatchEventEnum.concedeGoal ||
          matchEvents[i].type == MatchEventEnum.ownGoal) {
        goalsConceded++;
      }
    }

    Match updatedMatch = Match(
      id: match.id,
      teamId: match.teamId,
      opponent: match.opponent,
      goalsScored: goalsScored,
      goalsConceded: goalsConceded,
      date: match.date,
      hour: match.hour,
      status: MatchStatus
          .finished, // Set status to finished to indicate the match is finished
      lineups: match.lineups,
      isHome: match.isHome,
    );
    Either<Failure, void> result = await _matchRepository.updateMatch(
      updatedMatch,
    );
    if (result.isLeft()) {
      // If it is an error, return the error
      return result;
    }
    List<int> playerIds = matchEvents
        .map((event) => event.playerId1)
        .whereType<int>()
        .toSet()
        .toList();
    int i = 0;
    while (i < playerIds.length) {
      int playerId = playerIds[i];
      // Obtenemos las estadísticas actuales del jugador para acumular
      final currentPlayerResult = await _playerRepository.getPlayerById(
        playerId,
      );
      if (currentPlayerResult.isLeft()) {
        return currentPlayerResult.map((_) => null);
      }

      final currentPlayer = currentPlayerResult.getOrElse(
        () => const Player(teamId: 0, firstName: ''),
      );
      final perMatchStats = _getPlayerStats(matchEvents, playerId);
      final currentStats = currentPlayer.stats ?? const PlayerStats();

      final accumulatedStats = PlayerStats(
        id: currentStats.id,
        playerId: playerId,
        goals: currentStats.goals + perMatchStats.goals,
        assists: currentStats.assists + perMatchStats.assists,
        yellowCards: currentStats.yellowCards + perMatchStats.yellowCards,
        redCards: currentStats.redCards + perMatchStats.redCards,
        matchesPlayed: currentStats.matchesPlayed + 1,
      );

      result = await _playerRepository.updatePlayerStats(
        playerId,
        accumulatedStats,
      );
      if (result.isLeft()) {
        // If it is an error, return the error
        return result;
      }
      i++;
    }
    return result;
  }

  PlayerStats _getPlayerStats(List<MatchEvent> events, int playerId) {
    int idPlayer = playerId;
    int goals = 0;
    int assists = 0;
    int yellowCards = 0;
    int redCards = 0;

    for (int i = 0; i < events.length; i++) {
      final e = events[i];

      // Goles: playerId1 es el goleador.
      if (e.playerId1 == idPlayer && e.type == MatchEventEnum.scoreGoal) {
        goals++;
      }

      // Asistencias: playerId2 es el asistente en el evento de gol.
      if (e.playerId2 == idPlayer && e.type == MatchEventEnum.scoreGoal) {
        assists++;
      }

      if (e.playerId1 == idPlayer && e.type == MatchEventEnum.yellowCard) {
        yellowCards++;
      }

      if (e.playerId1 == idPlayer && e.type == MatchEventEnum.redCard) {
        redCards++;
      }
    }

    return PlayerStats(
      id: 0, // This should be generated by the database when saving the stats
      playerId: idPlayer,
      goals: goals,
      assists: assists,
      yellowCards: yellowCards,
      redCards: redCards,
    );
  }
}
