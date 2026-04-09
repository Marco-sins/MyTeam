import 'package:football_manager/data/models/match_event_model.dart';
import 'package:football_manager/domain/entities/match_event.dart';

class MatchEventMapper {
  static MatchEventModel toModel(MatchEvent matchEvent) {
    return MatchEventModel(
      id: matchEvent.id,
      matchId: matchEvent.matchId,
      playerId1: matchEvent.playerId1,
      playerId2: matchEvent.playerId2,
      minute: matchEvent.minute,
      type: matchEvent.type,
      note: matchEvent.note,
    );
  }

  static MatchEvent toEntity(MatchEventModel matchEventModel) {
    return MatchEvent(
      id: matchEventModel.id,
      matchId: matchEventModel.matchId,
      playerId1: matchEventModel.playerId1,
      playerId2: matchEventModel.playerId2,
      minute: matchEventModel.minute,
      type: matchEventModel.type,
      note: matchEventModel.note,
    );
  }
}
