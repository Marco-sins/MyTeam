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
    required this.formationLines,
    required this.formationLabel,
    required this.fieldPositionPlayers,
    required this.sentOffPlayerIds,
    this.eventAggregates,
    required this.allEventMaps,
  });

  const MatchStatsState.initial()
    : isLoading = false,
      error = null,
      events = const [],
      playersById = const {},
      startingPlayers = const [],
      substitutePlayers = const [],
      isStarterById = const {},
      playerRatings = const {},
      formationLines = const [],
      formationLabel = null,
      fieldPositionPlayers = const [],
      sentOffPlayerIds = const {},
      eventAggregates = null,
      allEventMaps = const [];

  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> events;
  final Map<int, Player> playersById;
  final List<Player> startingPlayers;
  final List<Player> substitutePlayers;
  final Map<int, bool> isStarterById;
  final Map<int, double> playerRatings;
  /// Filas del campo (portero + líneas), p. ej. [1,4,4,2]. Vacío = no hay dibujo.
  final List<int> formationLines;
  /// Clave de formación guardada (`4-4-2`, …) o null si se infirió por posiciones.
  final String? formationLabel;
  /// Titulares en el diagrama: alineación **inicial** ([MatchLineup.initialPosition]) en
  /// partidos finalizados; [sentOffPlayerIds] se aplica en la UI de lectura.
  final List<Player?> fieldPositionPlayers;
  final Set<int> sentOffPlayerIds;

  /// Conteos de tiros, faltas, córners y tarjetas (misma fuente que el gestor en vivo).
  final MatchEventAggregates? eventAggregates;

  /// Todos los eventos del partido (misma base que [calculatePlayerRating]), no el listado
  /// de cronología filtrada.
  final List<Map<String, dynamic>> allEventMaps;

  MatchStatsState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? events,
    Map<int, Player>? playersById,
    List<Player>? startingPlayers,
    List<Player>? substitutePlayers,
    Map<int, bool>? isStarterById,
    Map<int, double>? playerRatings,
    List<int>? formationLines,
    String? formationLabel,
    List<Player?>? fieldPositionPlayers,
    Set<int>? sentOffPlayerIds,
    MatchEventAggregates? eventAggregates,
    List<Map<String, dynamic>>? allEventMaps,
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
      formationLines: formationLines ?? this.formationLines,
      formationLabel: formationLabel ?? this.formationLabel,
      fieldPositionPlayers: fieldPositionPlayers ?? this.fieldPositionPlayers,
      sentOffPlayerIds: sentOffPlayerIds ?? this.sentOffPlayerIds,
      eventAggregates: eventAggregates ?? this.eventAggregates,
      allEventMaps: allEventMaps ?? this.allEventMaps,
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
    formationLines,
    formationLabel,
    fieldPositionPlayers,
    sentOffPlayerIds,
    eventAggregates,
    allEventMaps,
  ];
}
