class Match {
  final int id;
  final int teamId;
  final String opponent;
  final int goalsScored;
  final int goalsConceded;
  final DateTime date;
  final bool status;

  Match({
    required this.id,
    required this.teamId,
    required this.opponent,
    required this.goalsScored,
    required this.goalsConceded,
    required this.date,
    required this.status,
  });
}