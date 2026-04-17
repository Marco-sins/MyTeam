import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/repositories/i_match_event_repository.dart';

class DeleteMatchEventUseCase {
  final IMatchEventRepository _matchEventRepository;

  DeleteMatchEventUseCase(this._matchEventRepository);

  Future<Either<Failure, void>> call(
    MatchEvent matchEvent,
    AuthUser user,
    int teamId,
  ) async {
    final teamRole = user.teamRoles[teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure('You do not have permission to delete this match event.'),
      );
    }
    final response = await _matchEventRepository.deleteMatchEvent(matchEvent.id);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
