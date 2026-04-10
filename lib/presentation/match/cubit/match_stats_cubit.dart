import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';

part 'match_stats_state.dart';

class MatchStatsCubit extends Cubit<MatchStatsState> {
  MatchStatsCubit({required this.match, required this.getPlayersByTeamUseCase})
    : super(const MatchStatsState.initial());

  final Match match;
  final GetPlayersByTeamUseCase getPlayersByTeamUseCase;

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
          .select('player_id, is_start')
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
