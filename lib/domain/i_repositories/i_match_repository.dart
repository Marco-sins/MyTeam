abstract class IMatchRepository {
  Future<List<Match>> getMatches();
  Future<Match> getMatchById(int id);
  Future<void> addMatch(Match match);
  Future<void> updateMatch(Match match);
  Future<void> deleteMatch(int id);
  Future<List<Match>> getMatchesByTeamId(int teamId);
}