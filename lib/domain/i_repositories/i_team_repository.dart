import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/team.dart';

abstract class ITeamRepository {
  Future<Either<Failure, List<Team>>> getTeams();
  Future<Either<Failure, Team>> getTeamById(int id);
  Future<Either<Failure, Unit>> createTeam(Team team);
  Future<Either<Failure, Unit>> updateTeam(Team team);
  Future<Either<Failure, Unit>> deleteTeam(int id);
  Future<Either<Failure, String>> uploadLogo(Uint8List bytes, String fileName);
}
