import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/team_member_access.dart';
import 'package:football_manager/domain/i_repositories/i_team_repository.dart';

class GetTeamMembersUseCase {
  final ITeamRepository _teamRepository;

  GetTeamMembersUseCase(this._teamRepository);

  Future<Either<Failure, List<TeamMemberAccess>>> call(int teamId) {
    return _teamRepository.getTeamMembers(teamId);
  }
}
