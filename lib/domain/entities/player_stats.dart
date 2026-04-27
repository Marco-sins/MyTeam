class PlayerStats {
  final int id;
  final int playerId;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int matchesPlayed;
  final int minutesPlayed;
  final int timesStarted;

  /// Media de notas (una fila alineación por partido) en partidos finalizados.
  /// No se persiste en `player_stats`; se calcula al cargar la plantilla por equipo.
  final double? averageMatchRating;

  const PlayerStats({
    this.id = 0,
    this.playerId = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.matchesPlayed = 0,
    this.minutesPlayed = 0,
    this.timesStarted = 0,
    this.averageMatchRating,
  });
}