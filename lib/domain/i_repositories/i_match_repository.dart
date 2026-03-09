import 'package:dartz/dartz.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/core/errors/failure/failure.dart';

abstract class IMatchRepository {
  Future<Either<Failure, List<Match>>> getMatches();
  Future<Either<Failure, Match>> getMatchById(int id);
  Future<Either<Failure, void>> createMatch(Match match);
  Future<Either<Failure, void>> updateMatch(Match match);
  Future<Either<Failure, void>> deleteMatch(int id);
  Future<Either<Failure, List<Match>>> getMatchesByTeamId(int teamId);
}