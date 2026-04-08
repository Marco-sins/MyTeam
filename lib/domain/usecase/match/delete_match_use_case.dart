import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/i_repositories/i_match_repository.dart';

class DeleteMatchUseCase {
  final IMatchRepository _matchRepository;

  DeleteMatchUseCase(this._matchRepository);

  Future<Either<Failure, void>> call(Match match, AuthUser user) async {
    if (user.teamRoles[match.teamId] != UserRole.admin) {
      return Left(
        PermissionFailure('You do not have permission to delete this match.'),
      );
    }
    final response = await _matchRepository.deleteMatch(match.id);
    if (response.isLeft()) {
      return response;
    }
    return const Right(null);
  }
}
