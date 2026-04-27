class MatchLineup {
  final int id;
  final int playerId;
  final int matchId;
  final bool isStarting;
  final int minutesPlayed;
  final int? position;
  /// Hueco en el campo al **inicio** del partido (inmutable tras fijarse en BD).
  /// [position] sigue el desplazamiento en vivo.
  final int? initialPosition;
  final double rating;

  const MatchLineup({
    required this.id,
    required this.playerId,
    required this.matchId,
    required this.isStarting,
    this.minutesPlayed = 0,
    this.position,
    this.initialPosition,
    this.rating = 5,
  });
}
