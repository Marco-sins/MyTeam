import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

class GetTeamsUseCase {
  final ITeamRepository _teamRepository;

  GetTeamsUseCase(this._teamRepository);

  Future<Either<Failure, List<Team>>> call() async {
    return _teamRepository.getTeams();
  }
}
