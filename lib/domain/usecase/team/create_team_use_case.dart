import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

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
