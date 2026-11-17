import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/team_member_row.dart';

abstract class ITeamRepository {
  Future<Either<Failure, List<Team>>> getTeams();
  Future<Either<Failure, Team>> getTeamById(int id);
  Future<Either<Failure, Unit>> createTeam(Team team);
  Future<Either<Failure, Unit>> updateTeam(Team team);
  Future<Either<Failure, Unit>> deleteTeam(int id);
  Future<Either<Failure, Unit>> removeSelfFromTeam({
    required int teamId,
    required String userId,
  });
  Future<Either<Failure, String>> uploadLogo(Uint8List bytes, String fileName);
  Future<Either<Failure, List<TeamMemberRow>>> getTeamMemberRows(int teamId);
  Future<Either<Failure, bool>> isUserMemberOfTeam({
    required int teamId,
    required String userId,
  });
  Future<Either<Failure, Unit>> removeTeamMember({
    required int teamId,
    required String userId,
  });
}
