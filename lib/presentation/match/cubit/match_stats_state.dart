part of 'match_stats_cubit.dart';

class MatchStatsState extends Equatable {
  const MatchStatsState({
    required this.isLoading,
    required this.error,
    required this.events,
    required this.playersById,
    required this.startingPlayers,
    required this.substitutePlayers,
    required this.isStarterById,
    required this.playerRatings,
  });

  const MatchStatsState.initial()
    : isLoading = false,
      error = null,
      events = const [],
      playersById = const {},
      startingPlayers = const [],
      substitutePlayers = const [],
      isStarterById = const {},
      playerRatings = const {};

  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> events;
  final Map<int, Player> playersById;
  final List<Player> startingPlayers;
  final List<Player> substitutePlayers;
  final Map<int, bool> isStarterById;
  final Map<int, double> playerRatings;

  MatchStatsState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? events,
    Map<int, Player>? playersById,
    List<Player>? startingPlayers,
    List<Player>? substitutePlayers,
    Map<int, bool>? isStarterById,
    Map<int, double>? playerRatings,
  }) {
    return MatchStatsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      events: events ?? this.events,
      playersById: playersById ?? this.playersById,
      startingPlayers: startingPlayers ?? this.startingPlayers,
      substitutePlayers: substitutePlayers ?? this.substitutePlayers,
      isStarterById: isStarterById ?? this.isStarterById,
      playerRatings: playerRatings ?? this.playerRatings,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    events,
    playersById,
    startingPlayers,
    substitutePlayers,
    isStarterById,
    playerRatings,
  ];
}
