/// Representa una asistencia registrada para un jugador en una fecha.
class Attendance {
  final int id;
  final int teamId;
  final int playerId;
  final DateTime date;
  final bool attended;

  const Attendance({
    required this.id,
    required this.teamId,
    required this.playerId,
    required this.date,
    required this.attended,
  });
}
