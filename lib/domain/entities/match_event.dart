import 'package:tfg1/domain/entities/enum/match_event_enum.dart';

class MatchEvent {
  final int id;
  final int matchId;
  final int? playerId;
  final int? player2Id;
  final int minute;
  final MatchEventEnum type;
  final String? note;

  const MatchEvent({
    required this.id,
    required this.matchId,
    this.playerId,
    required this.minute,
    required this.type,
    this.note, 
    this.player2Id,
  });
}