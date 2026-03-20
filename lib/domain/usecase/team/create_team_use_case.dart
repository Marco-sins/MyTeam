import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/i_repositories/i_team_repository.dart';

class CreateTeamUseCase {
  final ITeamRepository _teamRepository;

  CreateTeamUseCase(this._teamRepository);

  Future<Either<Failure, void>> call(Team team) async {
    final response = await _teamRepository.createTeam(team);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
