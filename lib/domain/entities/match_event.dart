import 'package:football_manager/domain/entities/enum/match_event_enum.dart';

class MatchEvent {
  final int id;
  final int matchId;
  final int? playerId1;
  final int? playerId2;
  final int minute;
  final MatchEventEnum type;
  final String? note;

  const MatchEvent({
    required this.id,
    required this.matchId,
    this.playerId1,
    this.playerId2,
    required this.minute,
    required this.type,
    this.note,
  });
}
