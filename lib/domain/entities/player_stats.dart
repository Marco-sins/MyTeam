/// Estadísticas acumuladas de un jugador (goles, asistencias, tarjetas,
/// minutos, partidos jugados). Se utiliza para mostrar resúmenes y rankings.
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
  });
}
