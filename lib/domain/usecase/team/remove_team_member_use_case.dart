import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

class RemoveTeamMemberUseCase {
  RemoveTeamMemberUseCase(this._teamRepository);

  final ITeamRepository _teamRepository;

  Future<Either<Failure, Unit>> call({
    required int teamId,
    required String userId,
  }) {
    return _teamRepository.removeTeamMember(teamId: teamId, userId: userId);
  }
}
