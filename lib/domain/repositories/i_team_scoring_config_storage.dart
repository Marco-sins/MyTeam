import 'package:football_manager/domain/entities/team_scoring_config.dart';

/// Persistencia local de la configuración de puntuación por equipo (SharedPreferences en data).
abstract class ITeamScoringConfigStorage {
  TeamScoringConfig? load(int teamId);
  Future<void> save(int teamId, TeamScoringConfig config);
}
