/// Conteos derivados de la tabla [match_events] para marcador, tiros, faltas y córners.
class MatchEventAggregates {
  final int goalsScored;
  final int goalsConceded;
  final int shotsOur;
  final int shotsRival;
  final int foulsOur;
  final int foulsRival;
  final int cornersOur;
  final int cornersRival;

  const MatchEventAggregates({
    required this.goalsScored,
    required this.goalsConceded,
    required this.shotsOur,
    required this.shotsRival,
    required this.foulsOur,
    required this.foulsRival,
    required this.cornersOur,
    required this.cornersRival,
  });
}
