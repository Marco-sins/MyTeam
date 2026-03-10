import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/match_event.dart';

abstract class IMatchEventRepository {
  Future<Either<Failure, List<MatchEvent>>> getMatchEventsByMatch(int matchId);
  Future<Either<Failure, void>> saveMatchEvent(MatchEvent matchEvent);
  Future<Either<Failure, void>> updateMatchEvent(MatchEvent matchEvent);
  Future<Either<Failure, void>> deleteMatchEvent(int id);
}