import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/i_repositories/i_team_repository.dart';

class CreateTeam {
  final ITeamRepository _teamRepository;

  CreateTeam(this._teamRepository);

  Future<void> call(Team team) async {
    await _teamRepository.addTeam(team);
  }
}