class Attendance {
  final int id;
  final int teamId;
  final int playerId;
  final DateTime date;
  final bool attended;

  Attendance({
    required this.id,
    required this.teamId,
    required this.playerId,
    required this.date,
    required this.attended,
  });
}