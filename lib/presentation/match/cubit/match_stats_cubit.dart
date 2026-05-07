import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/usecase/match/get_match_lineups_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_events_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/match/utils/match_formation_utils.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';

part 'match_stats_state.dart';

/// Convierte eventos de dominio a mapas consumibles por la UI.
/// Lo hace proyectando solo los campos usados en las vistas.
List<Map<String, dynamic>> _matchEventsToEventMaps(List<MatchEvent> events) {
  return events
      .map(
        (e) => <String, dynamic>{
          'type': e.type,
          'player_id1': e.playerId1,
          'player_id2': e.playerId2,
          'note': e.note,
          'minute': e.minute,
          'point': e.point,
        },
      )
      .toList();
}

/// Cubit que prepara los datos de estadisticas del partido.
/// Orquesta casos de uso y calcula derivados para la vista.
class MatchStatsCubit extends Cubit<MatchStatsState> {
  /// Crea el cubit con las dependencias y estado inicial.
  /// Recibe el partido y casos de uso que se ejecutaran en [load].
  MatchStatsCubit({
    required this.match,
    required this.getPlayersByTeamUseCase,
    required this.getMatchEventsByMatchUseCase,
    required this.getMatchLineupsByMatchUseCase,
    required this.getLatestFormationNoteByMatchUseCase,
    required this.loadErrorMessage,
  }) : super(const MatchStatsState.initial());

  final Match match;
  final GetPlayersByTeamUseCase getPlayersByTeamUseCase;
  final GetMatchEventsByMatchUseCase getMatchEventsByMatchUseCase;
  final GetMatchLineupsByMatchUseCase getMatchLineupsByMatchUseCase;
  final GetLatestFormationNoteByMatchUseCase
  getLatestFormationNoteByMatchUseCase;
  final String loadErrorMessage;

  /// Calcula los ids expulsados a partir de los eventos.
  /// Cuenta rojas y dobles amarillas recorriendo la lista.
  Set<int> _sentOffPlayerIdsFromEvents(List<Map<String, dynamic>> events) {
    final yellowCounts = <int, int>{};
    final sentOff = <int>{};
    for (final event in events) {
      final rawType = event['type'];
      if (rawType == null) continue;
      final typeString = rawType.toString().split('.').last;
      final p1 = event['player_id1'] as int?;
      if (p1 == null) continue;
      if (typeString == 'redCard') {
        sentOff.add(p1);
      } else if (typeString == 'yellowCard') {
        final next = (yellowCounts[p1] ?? 0) + 1;
        yellowCounts[p1] = next;
        if (next >= 2) {
          sentOff.add(p1);
        }
      }
    }
    return sentOff;
  }

  /// Carga estadisticas del partido y emite el estado completo.
  /// Lo hace pidiendo eventos, jugadores y alineaciones, y derivando
  /// ratings, formacion y jugadores expulsados.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final eventsEither = await getMatchEventsByMatchUseCase(match.id);
      final matchEvents = eventsEither.fold<List<MatchEvent>?>((failure) {
        emit(state.copyWith(isLoading: false, error: failure.message));
        return null;
      }, (list) => list);
      if (matchEvents == null) return;

      final eventMaps = _matchEventsToEventMaps(matchEvents);

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

      // Ordena por dorsal para mostrar titulares y suplentes en orden.
      int byDorsal(Player a, Player b) {
        final na = a.number ?? 9999;
        final nb = b.number ?? 9999;
        return na.compareTo(nb);
      }

      starting.sort(byDorsal);
      subs.sort(byDorsal);

      final playerRatings = <int, double>{};
      for (final entry in playersById.entries) {
        playerRatings[entry.key] = calculatePlayerRating(entry.key, eventMaps);
      }

      final sentOff = _sentOffPlayerIdsFromEvents(eventMaps);

      var formationLines = <int>[];
      String? formationLabel;
      var fieldPositionPlayers = <Player?>[];

      if (match.status == MatchStatus.finished) {
        final formationEither = await getLatestFormationNoteByMatchUseCase(
          match.id,
        );
        final formationKey = formationEither.fold((_) => null, (n) => n);

        var maxPos = -1;
        for (final row in lineups) {
          final pos = row.position;
          if (pos != null && pos > maxPos) {
            maxPos = pos;
          }
        }

        final fromKey = MatchFormationUtils.linesFromKeyOrNull(formationKey);
        if (fromKey != null) {
          formationLines = fromKey;
          formationLabel = formationKey;
        } else if (maxPos >= 0) {
          formationLines = MatchFormationUtils.defaultLines(maxPos + 1);
          formationLabel = null;
        }

        if (formationLines.isNotEmpty) {
          final total = formationLines.fold<int>(0, (sum, n) => sum + n);
          fieldPositionPlayers = List<Player?>.filled(total, null);
          for (final row in lineups) {
            final playerId = row.playerId;
            final pos = row.position;
            if (pos == null) continue;
            if (pos < 0 || pos >= total) continue;
            if (sentOff.contains(playerId)) continue;
            final player = playersById[playerId];
            if (player == null) continue;
            fieldPositionPlayers[pos] = player;
          }
        }
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            error: null,
            events: eventMaps,
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
