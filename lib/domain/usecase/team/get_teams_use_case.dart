import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/i_repositories/i_team_repository.dart';

class GetTeamsUseCase {
  final ITeamRepository _teamRepository;

  GetTeamsUseCase(this._teamRepository);

  Future<Either<Failure, List<Team>>> call() async {
    return _teamRepository.getTeams();
  }
}
