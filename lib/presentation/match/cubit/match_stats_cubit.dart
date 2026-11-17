import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/entities/match_event_aggregates.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_event_aggregates_from_events_use_case.dart';
import 'package:football_manager/domain/entities/match_live_timeline_row.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/services/match_live_timeline_filter.dart';
import 'package:football_manager/domain/usecase/match/get_match_lineups_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_first_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_events_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/data/team_scoring_config_storage.dart';
import 'package:football_manager/presentation/match/utils/match_formation_utils.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';

part 'match_stats_state.dart';

List<Map<String, dynamic>> _matchEventsToEventMaps(List<MatchEvent> events) {
  return events
      .map(
        (e) => <String, dynamic>{
          'id': e.id,
          'match_id': e.matchId,
          // String estable para [canonicalMatchEventTypeKey] / cronología
          'type': e.type.toString().split('.').last,
          'player_id1': e.playerId1,
          'player_id2': e.playerId2,
          'note': e.note,
          'minute': e.minute,
          'created_at': e.createdAt?.toIso8601String(),
        },
      )
      .toList();
}

/// Misma [MatchLiveTimelineFilter.filterAndSort] que el gestor (incl. sin sustituciones
/// prematch; orden coherente para la cronología de detalle).
List<Map<String, dynamic>> _sortChronologyLikeManager(
  List<Map<String, dynamic>> eventMaps,
) {
  if (eventMaps.isEmpty) return eventMaps;
  final rows = eventMaps
      .map(
        (m) =>
            MatchLiveTimelineRow.fromPostgresMap(Map<String, dynamic>.from(m)),
      )
      .toList();
  final sorted = MatchLiveTimelineFilter.filterAndSort(rows);
  return sorted.map((e) => e.toLegacyMap()).toList();
}

class MatchStatsCubit extends Cubit<MatchStatsState> {
  MatchStatsCubit({
    required this.match,
    required this.getPlayersByTeamUseCase,
    required this.getMatchEventsByMatchUseCase,
    required this.getMatchLineupsByMatchUseCase,
    required this.getFirstFormationNoteByMatchUseCase,
    required this.getLatestFormationNoteByMatchUseCase,
    required this.getMatchEventAggregatesFromEventsUseCase,
    required this.teamScoringConfigStorage,
    required this.loadErrorMessage,
  }) : super(const MatchStatsState.initial());

  final Match match;
  final GetPlayersByTeamUseCase getPlayersByTeamUseCase;
  final GetMatchEventsByMatchUseCase getMatchEventsByMatchUseCase;
  final GetMatchLineupsByMatchUseCase getMatchLineupsByMatchUseCase;
  final GetFirstFormationNoteByMatchUseCase getFirstFormationNoteByMatchUseCase;
  final GetLatestFormationNoteByMatchUseCase
  getLatestFormationNoteByMatchUseCase;
  final GetMatchEventAggregatesFromEventsUseCase
  getMatchEventAggregatesFromEventsUseCase;
  final TeamScoringConfigStorage teamScoringConfigStorage;
  final String loadErrorMessage;

  Set<int> _sentOffPlayerIdsFromEvents(List<Map<String, dynamic>> events) {
    final yellowCounts = <int, int>{};
    final sentOff = <int>{};
    for (final event in events) {
      final rawType = event['type'];
      if (rawType == null) continue;
      final typeString = canonicalMatchEventTypeKey(rawType);
      final p1 = event['player_id1'] as int?;
      if (p1 == null) continue;
      if (typeString == 'redcard') {
        sentOff.add(p1);
      } else if (typeString == 'yellowcard') {
        final next = (yellowCounts[p1] ?? 0) + 1;
        yellowCounts[p1] = next;
        if (next >= 2) {
          sentOff.add(p1);
        }
      }
    }
    return sentOff;
  }

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final eventsEither = await getMatchEventsByMatchUseCase(match.id);
      final matchEvents = eventsEither.fold<List<MatchEvent>?>((failure) {
        emit(state.copyWith(isLoading: false, error: failure.message));
        return null;
      }, (list) => list);
      if (matchEvents == null) return;

      MatchEventAggregates? eventAggregates;
      if (match.status == MatchStatus.finished) {
        final aggEither = await getMatchEventAggregatesFromEventsUseCase(
          match.id,
        );
        eventAggregates = aggEither.fold((_) => null, (a) => a);
      } else {
        eventAggregates = null;
      }

      final fullEventMaps = _matchEventsToEventMaps(matchEvents);
      final eventMaps = _sortChronologyLikeManager(fullEventMaps);
      final teamScoring = teamScoringConfigStorage.load(match.teamId);

      final playersEither = await getPlayersByTeamUseCase(match.teamId);
      final playersById = playersEither.fold<Map<int, Player>?>((f) {
        emit(state.copyWith(isLoading: false, error: f.message));
        return null;
      }, (players) => {for (final p in players) p.id: p});
      if (playersById == null) return;

      final lineupsEither = await getMatchLineupsByMatchUseCase(match.id);
      final lineups = lineupsEither.fold((failure) {
        emit(state.copyWith(isLoading: false, error: failure.message));
        return null;
      }, (list) => list);
      if (lineups == null) return;

      final starting = <Player>[];
      final subs = <Player>[];
      final isStarterById = <int, bool>{};

      for (final row in lineups) {
        final player = playersById[row.playerId];
        if (player == null) continue;
        final isStart = row.isStarting;
        isStarterById[player.id] = isStart;
        if (isStart) {
          starting.add(player);
        } else {
          subs.add(player);
        }
      }

      int byDorsal(Player a, Player b) {
        final na = a.number ?? 9999;
        final nb = b.number ?? 9999;
        return na.compareTo(nb);
      }

      starting.sort(byDorsal);
      subs.sort(byDorsal);

      final playerRatings = <int, double>{};
      for (final entry in playersById.entries) {
        playerRatings[entry.key] = calculatePlayerRating(
          entry.key,
          fullEventMaps,
          teamScoring: teamScoring,
        );
      }

      final sentOff = _sentOffPlayerIdsFromEvents(fullEventMaps);

      var formationLines = <int>[];
      String? formationLabel;
      var fieldPositionPlayers = <Player?>[];

      if (match.status == MatchStatus.finished) {
        int? slotCountFromFormationKey(String? key) {
          final fromKey = MatchFormationUtils.linesFromKeyOrNull(key);
          if (fromKey == null) {
            return null;
          }
          return fromKey.fold<int>(0, (sum, n) => sum + n);
        }

        var maxPos = -1;
        for (final row in lineups) {
          if (!row.isStarting) {
            continue;
          }
          final pos = row.initialPosition ?? row.position;
          if (pos != null && pos > maxPos) {
            maxPos = pos;
          }
        }

        final firstFormationEither = await getFirstFormationNoteByMatchUseCase(
          match.id,
        );
        final firstFormationKey = firstFormationEither.fold(
          (_) => null,
          (n) => n,
        );
        final latestFormationEither =
            await getLatestFormationNoteByMatchUseCase(match.id);
        final latestFormationKey = latestFormationEither.fold(
          (_) => null,
          (n) => n,
        );

        final neededSlots = maxPos < 0 ? 0 : maxPos + 1;
        String? formationKey;
        if (neededSlots > 0) {
          final cFirst = slotCountFromFormationKey(firstFormationKey);
          final cLast = slotCountFromFormationKey(latestFormationKey);
          if (cFirst == neededSlots) {
            formationKey = firstFormationKey;
          } else if (cLast == neededSlots) {
            formationKey = latestFormationKey;
          } else {
            formationKey = firstFormationKey ?? latestFormationKey;
          }
        } else {
          formationKey = firstFormationKey ?? latestFormationKey;
        }

        final startingRowCount = lineups.where((r) => r.isStarting).length;

        final fromKey = MatchFormationUtils.linesFromKeyOrNull(formationKey);
        if (fromKey != null) {
          formationLines = fromKey;
          formationLabel = formationKey;
        } else if (maxPos >= 0) {
          formationLines = MatchFormationUtils.defaultLines(maxPos + 1);
          formationLabel = null;
        } else if (startingRowCount > 0) {
          formationLines = MatchFormationUtils.defaultLines(startingRowCount);
          formationLabel = null;
        }

        if (formationLines.isNotEmpty) {
          final total = formationLines.fold<int>(0, (sum, n) => sum + n);
          fieldPositionPlayers = List<Player?>.filled(total, null);

          int byDorsal(Player a, Player b) {
            final na = a.number ?? 9999;
            final nb = b.number ?? 9999;
            return na.compareTo(nb);
          }

          final placedStarterIds = <int>{};
          for (final row in lineups) {
            if (!row.isStarting) {
              continue;
            }
            final playerId = row.playerId;
            final pos = row.initialPosition ?? row.position;
            if (pos == null || pos < 0 || pos >= total) {
              continue;
            }
            final player = playersById[playerId];
            if (player == null) {
              continue;
            }
            fieldPositionPlayers[pos] = player;
            placedStarterIds.add(playerId);
          }

          final startersMissingSlot = <Player>[];
          for (final row in lineups) {
            if (!row.isStarting) {
              continue;
            }
            final playerId = row.playerId;
            if (placedStarterIds.contains(playerId)) {
              continue;
            }
            final player = playersById[playerId];
            if (player == null) {
              continue;
            }
            startersMissingSlot.add(player);
          }
          startersMissingSlot.sort(byDorsal);

          var u = 0;
          for (var i = 0; i < total && u < startersMissingSlot.length; i++) {
            if (fieldPositionPlayers[i] == null) {
              fieldPositionPlayers[i] = startersMissingSlot[u++];
            }
          }
        }
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            error: null,
            events: eventMaps,
            eventAggregates: eventAggregates,
            allEventMaps: fullEventMaps,
            playersById: playersById,
            startingPlayers: starting,
            substitutePlayers: subs,
            isStarterById: isStarterById,
            playerRatings: playerRatings,
            formationLines: formationLines,
            formationLabel: formationLabel,
            fieldPositionPlayers: fieldPositionPlayers,
            sentOffPlayerIds: sentOff,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: loadErrorMessage));
      }
    }
  }
}
