/// Conteos derivados de la tabla [match_events] para marcador y tiros.
class MatchEventAggregates {
  final int goalsScored;
  final int goalsConceded;
  final int shotsOur;
  final int shotsRival;

  const MatchEventAggregates({
    required this.goalsScored,
    required this.goalsConceded,
    required this.shotsOur,
    required this.shotsRival,
  });
}
