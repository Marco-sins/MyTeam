import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/i_repositories/i_match_repository.dart';

class UpdateMatchUseCase {
  final IMatchRepository _matchRepository;

  UpdateMatchUseCase(this._matchRepository);

  Future<Either<Failure, void>> call(Match match, AuthUser user) async {
    final teamRole = user.teamRoles[match.teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure('You do not have permission to update this match.'),
      );
    }

    final result = await _matchRepository.updateMatch(match);
    if (result.isLeft()) {
      return result;
    }

    return const Right(null);
  }
}
