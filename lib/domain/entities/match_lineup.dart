class MatchLineup {
  final int id;
  final int playerId;
  final int matchId;
  final bool isStarting;
  final int minutesPlayed;
  final int rating;

  MatchLineup({
    required this.id,
    required this.playerId,
    required this.matchId,
    required this.isStarting,
    required this.minutesPlayed,
    required this.rating,
  });
}