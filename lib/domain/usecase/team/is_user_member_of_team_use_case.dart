import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

class IsUserMemberOfTeamUseCase {
  IsUserMemberOfTeamUseCase(this._teamRepository);

  final ITeamRepository _teamRepository;

  Future<Either<Failure, bool>> call({
    required int teamId,
    required String userId,
  }) {
    return _teamRepository.isUserMemberOfTeam(
      teamId: teamId,
      userId: userId,
    );
  }
}
