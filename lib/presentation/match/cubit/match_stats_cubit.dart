import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/match/utils/match_formation_utils.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';

part 'match_stats_state.dart';

class MatchStatsCubit extends Cubit<MatchStatsState> {
  MatchStatsCubit({required this.match, required this.getPlayersByTeamUseCase})
    : super(const MatchStatsState.initial());

  final Match match;
  final GetPlayersByTeamUseCase getPlayersByTeamUseCase;

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

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final supabase = Supabase.instance.client;

      final rawEvents = await supabase
          .from('match_events')
          .select('id, type, minute, player_id1, player_id2, note, created_at')
          .eq('match_id', match.id)
          .order('minute', ascending: false)
          .order('created_at', ascending: false);

      final events = List<Map<String, dynamic>>.from(rawEvents as List);

      final playersEither = await getPlayersByTeamUseCase(match.teamId);

      Map<int, Player> playersById = {};
      String? error;

      playersEither.fold(
        (failure) => error = failure.message,
        (players) => playersById = {for (final p in players) p.id: p},
      );

      if (error != null) {
        emit(state.copyWith(isLoading: false, error: error));
        return;
      }

      final rawLineups = await supabase
          .from('match_lineup')
          .select('player_id, is_start, position')
          .eq('match_id', match.id);

      final starting = <Player>[];
      final subs = <Player>[];
      final isStarterById = <int, bool>{};

      for (final row in rawLineups as List) {
        final playerId = row['player_id'] as int?;
        if (playerId == null) continue;
        final player = playersById[playerId];
        if (player == null) continue;
        final isStart = (row['is_start'] as bool?) ?? false;
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
        playerRatings[entry.key] = calculatePlayerRating(entry.key, events);
      }

      final sentOff = _sentOffPlayerIdsFromEvents(events);

      var formationLines = <int>[];
      String? formationLabel;
      var fieldPositionPlayers = <Player?>[];

      if (match.status == MatchStatus.finished) {
        String? formationKey;
        try {
          final fRows = await supabase
              .from('match_events')
              .select('note')
              .eq('match_id', match.id)
              .eq('type', 'formation')
              .order('id', ascending: false)
              .limit(1);
          if (fRows.isNotEmpty) {
            final raw = fRows.first['note'] as String?;
            formationKey = raw?.trim();
            if (formationKey != null && formationKey.isEmpty) {
              formationKey = null;
            }
          }
        } catch (_) {}

        var maxPos = -1;
        for (final row in rawLineups as List) {
          final pos = row['position'] as int?;
          if (pos != null && pos > maxPos) {
            maxPos = pos;
          }
        }

        final fromKey = MatchFormationUtils.linesFromKeyOrNull(formationKey);
        if (fromKey != null) {
          formationLines = fromKey;
          formationLabel = formationKey;
        } else if (maxPos >= 0) {
          formationLines =
              MatchFormationUtils.defaultLines(maxPos + 1);
          formationLabel = null;
        }

        if (formationLines.isNotEmpty) {
          final total =
              formationLines.fold<int>(0, (sum, n) => sum + n);
          fieldPositionPlayers = List<Player?>.filled(total, null);
          for (final row in rawLineups as List) {
            final playerId = row['player_id'] as int?;
            final pos = row['position'] as int?;
            if (playerId == null || pos == null) continue;
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
            events: events,
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
        emit(
          state.copyWith(
            isLoading: false,
            error: 'No se han podido cargar los eventos del partido',
          ),
        );
      }
    }
  }
}
