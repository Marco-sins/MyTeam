import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/entities/team_member_row.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

class GetTeamMemberRowsUseCase {
  GetTeamMemberRowsUseCase(this._teamRepository);

  final ITeamRepository _teamRepository;

  Future<Either<Failure, List<TeamMemberRow>>> call(int teamId) {
    return _teamRepository.getTeamMemberRows(teamId);
  }
}
