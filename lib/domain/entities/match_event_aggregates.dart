/// Conteos derivados de la tabla [match_events] para marcador, tiros, faltas, córners y tarjetas.
class MatchEventAggregates {
  final int goalsScored;
  final int goalsConceded;
  final int shotsOur;
  final int shotsRival;
  final int foulsOur;
  final int foulsRival;
  final int cornersOur;
  final int cornersRival;
  final int yellowOur;
  final int yellowRival;
  final int redOur;
  final int redRival;

  const MatchEventAggregates({
    required this.goalsScored,
    required this.goalsConceded,
    required this.shotsOur,
    required this.shotsRival,
    required this.foulsOur,
    required this.foulsRival,
    required this.cornersOur,
    required this.cornersRival,
    required this.yellowOur,
    required this.yellowRival,
    required this.redOur,
    required this.redRival,
  });
}
