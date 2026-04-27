import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';

abstract class IMatchRepository {
  Future<Either<Failure, List<Match>>> getMatches();
  Future<Either<Failure, Match>> getMatchById(int id);
  Future<Either<Failure, Match>> createMatch(Match match);
  Future<Either<Failure, Unit>> addMatchLineup(MatchLineup lineup);
  Future<Either<Failure, Unit>> updateMatch(Match match);
  Future<Either<Failure, Unit>> deleteMatch(int id);
  Future<Either<Failure, List<Match>>> getMatchesByTeamId(int teamId);
  Future<Either<Failure, List<MatchLineup>>> getMatchLineupsByMatchId(
    int matchId,
  );
  Future<Either<Failure, Unit>> updateMatchLineupMinutesPlayed({
    required int matchId,
    required int playerId,
    required int minutesPlayed,
  });

  Future<Either<Failure, MatchStatus?>> getMatchStatus(int matchId);

  Future<Either<Failure, Unit>> updateMatchStatusHalfTime(int matchId);

  Future<Either<Failure, Unit>> updateMatchStatusSecondHalf({
    required int matchId,
    required DateTime secondHalfStart,
  });

  Future<Either<Failure, Set<int>>> getConvokedPlayerIdsForMatch(int matchId);

  /// [onFieldPositionByPlayerId] solo incluye titulares en campo; el resto va con `null`.
  Future<Either<Failure, Unit>> persistMatchLineupPositions({
    required int matchId,
    required List<int> convokedPlayerIds,
    required Map<int, int> onFieldPositionByPlayerId,
  });

  /// Copia [position] → [initial_position] donde aún sea null (al inicio del partido).
  Future<Either<Failure, Unit>> lockInitialLineupPositions(int matchId);

  Future<Either<Failure, Unit>> updateMatchLineupStarters({
    required int matchId,
    required List<int> starterPlayerIds,
  });

  Future<Either<Failure, List<({int playerId, int positionIndex})>>>
      getMatchLineupPositions(int matchId);
}
