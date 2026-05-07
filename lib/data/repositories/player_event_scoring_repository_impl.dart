/// Implementación del repositorio para reglas de puntuación de eventos.
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/server_failure.dart';
import 'package:football_manager/data/datasource/player_event_scoring_datasource.dart';
import 'package:football_manager/data/models/player_event_scoring_rule_model.dart';
import 'package:football_manager/domain/entities/player_event_scoring_rule.dart';
import 'package:football_manager/domain/repositories/player_event_scoring_repository.dart';
import 'dart:convert';

class PlayerEventScoringRepositoryImpl implements PlayerEventScoringRepository {
  final PlayerEventScoringDatasource _datasource;
  final SharedPreferences? _prefs;

  PlayerEventScoringRepositoryImpl(this._datasource, this._prefs);

  @override
  Future<Either<Failure, List<PlayerEventScoringRule>>> getRulesByTeam(
    int teamId,
  ) async {
    try {
      final rules = await _datasource.getRulesByTeam(teamId);
      return Right(rules);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlayerEventScoringRule?>> getRuleByTeamAndType(
    int teamId,
    String eventType,
  ) async {
    try {
      final rule = await _datasource.getRuleByTeamAndType(teamId, eventType);
      return Right(rule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlayerEventScoringRule>> createRule(
    PlayerEventScoringRule rule,
  ) async {
    try {
      final model = PlayerEventScoringRuleModel(
        id: rule.id,
        teamId: rule.teamId,
        eventType: rule.eventType,
        points: rule.points,
        enabled: rule.enabled,
        createdAt: rule.createdAt,
        updatedAt: rule.updatedAt,
      );
      final created = await _datasource.createRule(model);
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlayerEventScoringRule>> updateRule(
    PlayerEventScoringRule rule,
  ) async {
    try {
      final model = PlayerEventScoringRuleModel(
        id: rule.id,
        teamId: rule.teamId,
        eventType: rule.eventType,
        points: rule.points,
        enabled: rule.enabled,
        createdAt: rule.createdAt,
        updatedAt: DateTime.now(),
      );
      final updated = await _datasource.updateRule(model);
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRule(String ruleId) async {
    try {
      await _datasource.deleteRule(ruleId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlayerEventScoringRule>> upsertRule(
    PlayerEventScoringRule rule,
  ) async {
    try {
      final model = PlayerEventScoringRuleModel(
        id: rule.id,
        teamId: rule.teamId,
        eventType: rule.eventType,
        points: rule.points,
        enabled: rule.enabled,
        createdAt: rule.createdAt,
        updatedAt: DateTime.now(),
      );
      final upserted = await _datasource.upsertRule(model);
      return Right(upserted);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> migrateFromLocalStorage(int teamId) async {
    try {
      if (_prefs == null) {
        return const Right(null);
      }

      const prefsKey = 'player_event_rating_rules_v1';
      final raw = _prefs.getString(prefsKey);

      if (raw == null || raw.isEmpty) {
        return const Right(null);
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const Right(null);
      }

      // Migrar cada regla a la BD
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final rule = PlayerEventScoringRuleModel(
            id: item['id'] as String? ?? '',
            teamId: teamId,
            eventType: (item['key'] as String?)?.trim() ?? '',
            points: (item['points'] as num?)?.toDouble() ?? 0,
            enabled: item['enabled'] as bool? ?? true,
            createdAt: DateTime.now(),
          );

          // Si no tiene ID, Supabase lo generará
          if (rule.id.isEmpty) {
            await _datasource.createRule(rule.copyWith(id: ''));
          } else {
            await _datasource.upsertRule(rule);
          }
        }
      }

      // Limpiar SharedPreferences después de migrar
      await _prefs.remove(prefsKey);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Migration error: $e'));
    }
  }
}
