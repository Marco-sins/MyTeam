class MatchEvent {
  final int id;
  final int idMatch;
  final int idPlayer;
  final int minute;
  final String type;
  final String? note;

  MatchEvent({
    required this.id,
    required this.idMatch,
    required this.idPlayer,
    required this.minute,
    required this.type,
    this.note,
  });
}