import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/server_failure.dart';
import 'package:football_manager/core/errors/failure/unknow_failure.dart';
import 'package:football_manager/data/datasource/match_remote_datasource.dart';
import 'package:football_manager/data/mappers/match_lineup_mapper.dart';
import 'package:football_manager/data/mappers/match_mapper.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/match_lineup.dart';
import 'package:football_manager/domain/i_repositories/i_match_repository.dart';

class MatchRepository implements IMatchRepository {
  final MatchRemoteDatasource _remoteDatasource;

  MatchRepository(this._remoteDatasource);

  @override
  Future<Either<Failure, Unit>> addMatchLineup(MatchLineup lineup) async {
    try {
      await _remoteDatasource.addMatchLineup(MatchLineupMapper.toModel(lineup));
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Match>> createMatch(Match match) async {
    try {
      final created = await _remoteDatasource.createMatch(
        MatchMapper.toModel(match),
      );
      return Right(MatchMapper.toEntity(created));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMatch(int id) async {
    try {
      await _remoteDatasource.deleteMatch(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Match>> getMatchById(int id) async {
    try {
      final match = await _remoteDatasource.getMatchById(id);
      return Right(MatchMapper.toEntity(match));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getMatches() async {
    try {
      final result = await _remoteDatasource.getMatches();
      List<Match> matches = result.map((e) => MatchMapper.toEntity(e)).toList();
      return Right(matches);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getMatchesByTeamId(int teamId) async {
    try {
      final result = await _remoteDatasource.getMatchesByTeamId(teamId);
      List<Match> matches = result.map((e) => MatchMapper.toEntity(e)).toList();
      return Right(matches);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMatch(Match match) async {
    try {
      await _remoteDatasource.updateMatch(MatchMapper.toModel(match));
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MatchLineup>>> getMatchLineupsByMatchId(
    int matchId,
  ) async {
    try {
      final rows = await _remoteDatasource.getMatchLineupsByMatchId(matchId);
      return Right(
        rows.map(MatchLineupMapper.toEntity).toList(),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMatchLineupMinutesPlayed({
    required int matchId,
    required int playerId,
    required int minutesPlayed,
  }) async {
    try {
      await _remoteDatasource.updateMatchLineupMinutesPlayed(
        matchId: matchId,
        playerId: playerId,
        minutesPlayed: minutesPlayed,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure('Unexpected error: $e'));
    }
  }
}
