import 'package:tfg1/data/models/team_model.dart';
import 'package:tfg1/domain/entities/team.dart';

class TeamMapper {
  static TeamModel toModel(Team team) {
    return TeamModel(
      id: team.id,
      name: team.name,
      category: team.category,
      logoUrl: team.logoUrl,
    );
  }

  static Team toEntity(TeamModel teamModel) {
    return Team(
      id: teamModel.id,
      name: teamModel.name,
      category: teamModel.category,
      logoUrl: teamModel.logoUrl,
    );
  }
}