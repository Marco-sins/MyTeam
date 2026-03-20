import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/entities/match_event.dart';
import 'package:tfg1/domain/i_repositories/i_match_event_repository.dart';

class DeleteMatchEventUseCase {
  final IMatchEventRepository _matchEventRepository;

  DeleteMatchEventUseCase(this._matchEventRepository);

  Future<Either<Failure, void>> call(
    MatchEvent matchEvent,
    AuthUser user,
    int teamId,
  ) async {
    if (user.teamRoles[teamId] != UserRole.admin) {
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
