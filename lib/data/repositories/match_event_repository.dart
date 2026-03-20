import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/exception/server_exception.dart';
import 'package:tfg1/core/errors/exception/unknow_exception.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/core/errors/failure/unknow_failure.dart';
import 'package:tfg1/data/datasource/match_event_remote_datasource.dart';
import 'package:tfg1/data/mappers/match_event_mapper.dart';
import 'package:tfg1/data/models/match_event_model.dart';
import 'package:tfg1/domain/entities/match_event.dart';
import 'package:tfg1/domain/i_repositories/i_match_event_repository.dart';

class MatchEventRepository implements IMatchEventRepository {
  final MatchEventRemoteDatasource _remoteDatasource;

  MatchEventRepository(this._remoteDatasource);

  @override
  Future<Either<Failure, Unit>> deleteMatchEvent(int id) async {
    try {
      await _remoteDatasource.deleteMatchEvent(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MatchEvent>>> getMatchEventsByMatch(
    int matchId,
  ) async {
    try {
      final result = await _remoteDatasource.getMatchEventsByMatch(matchId);
      List<MatchEventModel> events = result
          .map((e) => MatchEventMapper.toModel(e))
          .toList();
      return Right(events);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveMatchEvent(MatchEvent matchEvent) async {
    try {
      await _remoteDatasource.saveMatchEvent(
        MatchEventMapper.toModel(matchEvent),
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMatchEvent(MatchEvent matchEvent) async {
    try {
      await _remoteDatasource.updateMatchEvent(
        MatchEventMapper.toModel(matchEvent),
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }
}
