import 'package:tfg1/data/models/match_event_model.dart';
import 'package:tfg1/domain/entities/match_event.dart';

class MatchEventMapper {
  static MatchEventModel toModel(MatchEvent matchEvent) {
    return MatchEventModel(
      id: matchEvent.id,
      matchId: matchEvent.matchId,
      playerId: matchEvent.playerId,
      player2Id: matchEvent.player2Id,
      minute: matchEvent.minute,
      type: matchEvent.type,
      note: matchEvent.note,
    );
  }

  static MatchEvent toEntity(MatchEventModel matchEventModel) {
    return MatchEvent(
      id: matchEventModel.id,
      matchId: matchEventModel.matchId,
      playerId: matchEventModel.playerId,
      player2Id: matchEventModel.player2Id,
      minute: matchEventModel.minute,
      type: matchEventModel.type,
      note: matchEventModel.note,
    );
  }
}