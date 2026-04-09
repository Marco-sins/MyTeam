import 'package:dartz/dartz.dart';
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
}
