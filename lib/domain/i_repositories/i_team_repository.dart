import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/team.dart';

abstract class ITeamRepository {
  Future<Either<Failure, List<Team>>> getTeams();
  Future<Either<Failure, Team>> getTeamById(int id);
  Future<Either<Failure, void>> addTeam(Team team);
  Future<Either<Failure, void>> updateTeam(Team team);
  Future<Either<Failure, void>> deleteTeam(int id);
}