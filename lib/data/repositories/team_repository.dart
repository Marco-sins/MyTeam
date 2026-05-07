import 'dart:typed_data';

/// Repositorio para la entidad `team` que traduce operaciones remotas a la
/// interfaz del dominio `ITeamRepository`.
import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/utils/repository_guard.dart';
import 'package:football_manager/data/datasource/team_remote_datasource.dart';
import 'package:football_manager/data/mappers/team_mapper.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

class TeamRepository implements ITeamRepository {
  final TeamRemoteDatasource _datasource;

  TeamRepository(this._datasource);

  @override
  Future<Either<Failure, Unit>> createTeam(Team team) {
    return runRepositoryGuard(() async {
      await _datasource.createTeam(TeamMapper.toModel(team));
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteTeam(int id) {
    return runRepositoryGuard(() async {
      await _datasource.deleteTeam(id);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> removeSelfFromTeam({
    required int teamId,
    required String userId,
  }) {
    return runRepositoryGuard(() async {
      await _datasource.removeSelfFromTeam(teamId: teamId, userId: userId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Team>> getTeamById(int id) {
    return runRepositoryGuard(() async {
      final result = await _datasource.getTeamById(id);
      return TeamMapper.toEntity(result);
    });
  }

  @override
  Future<Either<Failure, List<Team>>> getTeams() {
    return runRepositoryGuard(() async {
      final result = await _datasource.getTeams();
      return result.map(TeamMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> updateTeam(Team team) {
    return runRepositoryGuard(() async {
      await _datasource.updateTeam(TeamMapper.toModel(team));
      return unit;
    });
  }

  @override
  Future<Either<Failure, String>> uploadLogo(Uint8List bytes, String fileName) {
    return runRepositoryGuard(() => _datasource.uploadLogo(bytes, fileName));
  }
}
