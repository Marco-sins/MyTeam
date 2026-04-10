class MatchLineup {
  final int id;
  final int playerId;
  final int matchId;
  final bool isStarting;
  final int minutesPlayed;
  final int? position;
  final double rating;

  const MatchLineup({
    required this.id,
    required this.playerId,
    required this.matchId,
    required this.isStarting,
    this.minutesPlayed = 0,
    this.position,
    this.rating = 5,
  });
}
