import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:football_manager/domain/repositories/player_event_scoring_repository.dart';
import 'package:football_manager/presentation/match/utils/player_event_rating_settings_store.dart';

part 'player_event_rating_settings_state.dart';

class PlayerEventRatingSettingsCubit
    extends Cubit<PlayerEventRatingSettingsState> {
  PlayerEventRatingSettingsCubit(this._repository)
    : super(const PlayerEventRatingSettingsState.initial());

  final PlayerEventScoringRepository _repository;
  int? _currentTeamId;

  /// Carga las reglas para un equipo desde Supabase.
  Future<void> loadForTeam(int teamId) async {
    _currentTeamId = teamId;
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _repository.getRulesByTeam(teamId);

    result.fold(
      (failure) {
        // Si falla, usar valores por defecto
        PlayerEventRatingSettingsStore.instance.resetToDefaults();
        emit(
          state.copyWith(
            isLoading: false,
            rules: PlayerEventRatingSettingsStore.instance.rules,
            error: failure.toString(),
          ),
        );
      },
      (rulesFromDb) {
        // Convertir entidades de BD a reglas de UI con labels
        final uiRules = rulesFromDb.map((entity) {
          // Buscar el label en los defaults
          final defaultRule = PlayerEventRatingSettingsStore.defaultRules()
              .firstWhere(
                (r) => r.key.toLowerCase() == entity.eventType.toLowerCase(),
                orElse: () => PlayerEventRatingRule(
                  key: entity.eventType,
                  label: entity.eventType,
                  points: entity.points,
                  enabled: entity.enabled,
                ),
              );
          return PlayerEventRatingRule.fromEntity(entity, defaultRule.label);
        }).toList();

        if (uiRules.isEmpty) {
          // Si no hay reglas en la BD, usar defaults
          PlayerEventRatingSettingsStore.instance.resetToDefaults();
          emit(
            state.copyWith(
              isLoading: false,
              rules: PlayerEventRatingSettingsStore.instance.rules,
            ),
          );
        } else {
          PlayerEventRatingSettingsStore.instance.setRulesForTeam(
            teamId,
            uiRules,
          );
          emit(state.copyWith(isLoading: false, rules: uiRules));
        }
      },
    );
  }

  /// Migra datos desde SharedPreferences a la BD.
  Future<void> migrateFromLocalStorage(int teamId) async {
    if (_currentTeamId == null) {
      _currentTeamId = teamId;
    }

    final result = await _repository.migrateFromLocalStorage(teamId);

    result.fold(
      (failure) {
        emit(
          state.copyWith(error: 'Error en migración: ${failure.toString()}'),
        );
      },
      (_) {
        // Recargar reglas después de la migración
        loadForTeam(teamId);
      },
    );
  }

  Future<void> resetToDefaults() async {
    if (_currentTeamId == null) return;

    PlayerEventRatingSettingsStore.instance.resetToDefaults();
    final defaults = PlayerEventRatingSettingsStore.instance.rules;

    // Guardar los defaults en la BD para este equipo
    for (final rule in defaults) {
      final entity = rule.toEntity(_currentTeamId!);
      await _repository.upsertRule(entity);
    }

    emit(state.copyWith(rules: defaults));
  }

  Future<void> upsertRule(PlayerEventRatingRule rule) async {
    if (_currentTeamId == null) return;

    final entity = rule.toEntity(_currentTeamId!);
    final result = await _repository.upsertRule(entity);

    result.fold(
      (failure) {
        emit(state.copyWith(error: 'Error al guardar: ${failure.toString()}'));
      },
      (savedEntity) {
        // Actualizar en memoria y en la UI
        final current = List<PlayerEventRatingRule>.from(state.rules);
        final key = rule.key.trim().toLowerCase();
        final index = current.indexWhere((r) => r.key.toLowerCase() == key);

        late final List<PlayerEventRatingRule> next;
        if (index >= 0) {
          next = [...current];
          next[index] = rule.copyWith(dbId: savedEntity.id);
        } else {
          next = [...current, rule.copyWith(dbId: savedEntity.id)];
        }

        PlayerEventRatingSettingsStore.instance.setRulesForTeam(
          _currentTeamId!,
          next,
        );
        emit(state.copyWith(rules: next));
      },
    );
  }

  Future<void> deleteRule(String key) async {
    if (_currentTeamId == null) return;

    final rule = PlayerEventRatingSettingsStore.instance.ruleForKey(key);
    if (rule?.dbId == null) return;

    final result = await _repository.deleteRule(rule!.dbId!);

    result.fold(
      (failure) {
        emit(state.copyWith(error: 'Error al eliminar: ${failure.toString()}'));
      },
      (_) {
        // Actualizar en memoria
        final normalized = key.trim().toLowerCase();
        final next = state.rules
            .where((r) => r.key.toLowerCase() != normalized)
            .toList();

        PlayerEventRatingSettingsStore.instance.setRulesForTeam(
          _currentTeamId!,
          next,
        );
        emit(state.copyWith(rules: next));
      },
    );
  }
}
