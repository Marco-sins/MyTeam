/// Interface del repositorio para manejar reglas de puntuación de eventos.
import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/player_event_scoring_rule.dart';

abstract class PlayerEventScoringRepository {
  /// Obtiene todas las reglas de puntuación para un equipo.
  Future<Either<Failure, List<PlayerEventScoringRule>>> getRulesByTeam(
    int teamId,
  );

  /// Obtiene una regla específica.
  Future<Either<Failure, PlayerEventScoringRule?>> getRuleByTeamAndType(
    int teamId,
    String eventType,
  );

  /// Crea una nueva regla.
  Future<Either<Failure, PlayerEventScoringRule>> createRule(
    PlayerEventScoringRule rule,
  );

  /// Actualiza una regla existente.
  Future<Either<Failure, PlayerEventScoringRule>> updateRule(
    PlayerEventScoringRule rule,
  );

  /// Elimina una regla.
  Future<Either<Failure, void>> deleteRule(String ruleId);

  /// Crea o actualiza una regla.
  Future<Either<Failure, PlayerEventScoringRule>> upsertRule(
    PlayerEventScoringRule rule,
  );

  /// Migra datos desde SharedPreferences a la base de datos.
  Future<Either<Failure, void>> migrateFromLocalStorage(int teamId);
}
