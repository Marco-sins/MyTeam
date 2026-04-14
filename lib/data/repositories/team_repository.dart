import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/server_failure.dart';
import 'package:football_manager/data/datasource/team_remote_datasource.dart';
import 'package:football_manager/data/mappers/team_mapper.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/i_repositories/i_team_repository.dart';

class TeamRepository implements ITeamRepository {
  final TeamRemoteDatasource _datasource;

  TeamRepository(this._datasource);

  @override
  Future<Either<Failure, Unit>> createTeam(Team team) async {
    try {
      await _datasource.createTeam(TeamMapper.toModel(team));
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTeam(int id) async {
    try {
      await _datasource.deleteTeam(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeSelfFromTeam({
    required int teamId,
    required String userId,
  }) async {
    try {
      await _datasource.removeSelfFromTeam(teamId: teamId, userId: userId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Team>> getTeamById(int id) async {
    try {
      final result = await _datasource.getTeamById(id);
      Team team = TeamMapper.toEntity(result);
      return Right(team);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Team>>> getTeams() async {
    try {
      final result = await _datasource.getTeams();
      List<Team> teams = result.map((e) => TeamMapper.toEntity(e)).toList();
      return Right(teams);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTeam(Team team) async {
    try {
      await _datasource.updateTeam(TeamMapper.toModel(team));
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadLogo(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final url = await _datasource.uploadLogo(bytes, fileName);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
