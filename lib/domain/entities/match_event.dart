import 'package:tfg1/domain/entities/enum/match_event_enum.dart';

class MatchEvent {
  final int id;
  final int idMatch;
  final int? idPlayer;
  final int? idPlayer2;
  final int minute;
  final MatchEventEnum type;
  final String? note;

  MatchEvent({
    required this.id,
    required this.idMatch,
    this.idPlayer,
    required this.minute,
    required this.type,
    this.note, 
    this.idPlayer2,
  });
}