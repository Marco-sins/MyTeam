import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/team.dart';

abstract class ITeamRepository {
  Future<Either<Failure, List<Team>>> getTeams();
  Future<Either<Failure, Team>> getTeamById(int id);
  Future<Either<Failure, Unit>> addTeam(Team team);
  Future<Either<Failure, Unit>> updateTeam(Team team);
  Future<Either<Failure, Unit>> deleteTeam(int id);
}
