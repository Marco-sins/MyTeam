/// Totales derivados de partidos finalizados y filas registradas (lineup + eventos).
class PlayerParticipationTotals {
  final int matchesPlayed;
  final int timesStarted;
  final int minutesPlayedSum;
  final double? averageMatchRating;

  const PlayerParticipationTotals({
    required this.matchesPlayed,
    required this.timesStarted,
    required this.minutesPlayedSum,
    this.averageMatchRating,
  });

  static const zero = PlayerParticipationTotals(
    matchesPlayed: 0,
    timesStarted: 0,
    minutesPlayedSum: 0,
    averageMatchRating: null,
  );
}
