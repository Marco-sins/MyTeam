import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/i_repositories/i_match_event_repository.dart';
import 'package:football_manager/domain/i_repositories/i_match_repository.dart';
import 'package:football_manager/domain/i_repositories/i_player_repository.dart';
import 'package:football_manager/domain/utils/match_minutes_utils.dart';

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
    final teamRole = user.teamRoles[match.teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure('You do not have permission to finish this match.'),
      );
    }
    Either<Failure, List<MatchEvent>> events = await _matchEventRepository
        .getMatchEventsByMatch(match.id);
    if (events.isLeft()) {
      return events;
    }

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
      status: MatchStatus.finished,
      lineups: match.lineups,
      isHome: match.isHome,
    );
    Either<Failure, void> result = await _matchRepository.updateMatch(
      updatedMatch,
    );
    if (result.isLeft()) {
      return result;
    }

    final lineupsResult = await _matchRepository.getMatchLineupsByMatchId(
      match.id,
    );
    if (lineupsResult.isLeft()) {
      return lineupsResult.map<void>((_) {});
    }
    final List<MatchLineup> lineups = lineupsResult.getOrElse(() => []);

    MatchLineup? lineupFor(int playerId) {
      for (final l in lineups) {
        if (l.playerId == playerId) {
          return l;
        }
      }
      return null;
    }

    final Set<int> playerIdsToUpdate = {};
    for (final l in lineups) {
      playerIdsToUpdate.add(l.playerId);
    }
    for (final e in matchEvents) {
      if (e.playerId1 != null) {
        playerIdsToUpdate.add(e.playerId1!);
      }
      if (e.playerId2 != null) {
        playerIdsToUpdate.add(e.playerId2!);
      }
    }

    for (final playerId in playerIdsToUpdate) {
      final row = lineupFor(playerId);
      final bool isStarter = row?.isStarting ?? false;
      final int minutesThisMatch = minutesPlayedForPlayer(
        events: matchEvents,
        playerId: playerId,
        isStarter: isStarter,
      );

      final eventStats = _getPlayerStats(matchEvents, playerId);

      final bool participated =
          minutesThisMatch > 0 ||
          isStarter ||
          eventStats.goals > 0 ||
          eventStats.assists > 0 ||
          eventStats.yellowCards > 0 ||
          eventStats.redCards > 0;

      if (!participated) {
        continue;
      }

      if (row != null) {
        final lineupWrite = await _matchRepository.updateMatchLineupMinutesPlayed(
          matchId: match.id,
          playerId: playerId,
          minutesPlayed: minutesThisMatch,
        );
        if (lineupWrite.isLeft()) {
          return lineupWrite;
        }
      }

      final currentPlayerResult = await _playerRepository.getPlayerById(
        playerId,
      );
      if (currentPlayerResult.isLeft()) {
        return currentPlayerResult.map<void>((_) {});
      }

      final currentPlayer = currentPlayerResult.getOrElse(
        () => const Player(teamId: 0, firstName: ''),
      );
      final currentStats = currentPlayer.stats ?? const PlayerStats();

      // Partidos / minutos / titular: se recalculan desde BD al cerrar (sync).
      final accumulatedStats = PlayerStats(
        id: currentStats.id,
        playerId: playerId,
        goals: currentStats.goals + eventStats.goals,
        assists: currentStats.assists + eventStats.assists,
        yellowCards: currentStats.yellowCards + eventStats.yellowCards,
        redCards: currentStats.redCards + eventStats.redCards,
        matchesPlayed: currentStats.matchesPlayed,
        minutesPlayed: currentStats.minutesPlayed,
        timesStarted: currentStats.timesStarted,
      );

      result = await _playerRepository.updatePlayerStats(
        playerId,
        accumulatedStats,
      );
      if (result.isLeft()) {
        return result;
      }
    }

    final syncResult = await _playerRepository.syncParticipationStatsForTeam(
      match.teamId,
    );
    return syncResult;
  }

  PlayerStats _getPlayerStats(List<MatchEvent> events, int playerId) {
    int idPlayer = playerId;
    int goals = 0;
    int assists = 0;
    int yellowCards = 0;
    int redCards = 0;

    for (int i = 0; i < events.length; i++) {
      final e = events[i];

      if (e.playerId1 == idPlayer && e.type == MatchEventEnum.scoreGoal) {
        goals++;
      }

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
      id: 0,
      playerId: idPlayer,
      goals: goals,
      assists: assists,
      yellowCards: yellowCards,
      redCards: redCards,
    );
  }
}
