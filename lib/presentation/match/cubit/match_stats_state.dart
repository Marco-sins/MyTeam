part of 'match_stats_cubit.dart';

/// Estado inmutable con los datos listos para la pantalla de estadisticas.
/// Se construye desde el cubit y se compara por valor con [Equatable].
class MatchStatsState extends Equatable {
  /// Crea un estado completo con todos los campos obligatorios.
  /// Lo hace asignando cada propiedad para mantener inmutabilidad.
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
  });

  /// Estado inicial sin datos cargados ni errores.
  /// Lo hace usando colecciones vacias y banderas por defecto.
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
      sentOffPlayerIds = const {};

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

  /// Jugadores por hueco al final del partido (expulsados fuera del campo).
  final List<Player?> fieldPositionPlayers;
  final Set<int> sentOffPlayerIds;

  /// Crea una copia con cambios puntuales.
  /// Lo hace reusando los valores actuales cuando el parametro es null.
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
    );
  }

  /// Lista de props para comparacion por valor.
  /// Lo hace exponiendo todas las propiedades relevantes del estado.
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
  ];
}
