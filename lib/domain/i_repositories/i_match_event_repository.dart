import 'package:tfg1/domain/entities/match_event.dart';

abstract class IMatchEventRepository {
  Future<List<MatchEvent>> getMatchEventsByMatch(int matchId);
  Future<void> addMatchEvent(MatchEvent matchEvent);
  Future<void> updateMatchEvent(MatchEvent matchEvent);
  Future<void> deleteMatchEvent(int id);
}