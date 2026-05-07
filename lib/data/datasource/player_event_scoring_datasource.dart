/// Data source para acceder a las reglas de puntuación de eventos desde Supabase.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/data/models/player_event_scoring_rule_model.dart';

class PlayerEventScoringDatasource {
  final SupabaseClient _supabase;

  PlayerEventScoringDatasource(this._supabase);

  /// Obtiene todas las reglas de puntuación para un equipo.
  Future<List<PlayerEventScoringRuleModel>> getRulesByTeam(int teamId) async {
    try {
      final response = await _supabase
          .from('player_event')
          .select()
          .eq('id_team', teamId)
          .order('event_type');

      final rules = (response as List<dynamic>)
          .map(
            (e) =>
                PlayerEventScoringRuleModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      return rules;
    } catch (e) {
      throw Exception('Error fetching scoring rules: $e');
    }
  }

  /// Obtiene una regla específica por team_id y event_type.
  Future<PlayerEventScoringRuleModel?> getRuleByTeamAndType(
    int teamId,
    String eventType,
  ) async {
    try {
      final response = await _supabase
          .from('player_event')
          .select()
          .eq('id_team', teamId)
          .eq('event_type', eventType.trim())
          .maybeSingle();

      if (response == null) return null;

      return PlayerEventScoringRuleModel.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching scoring rule: $e');
    }
  }

  /// Crea una nueva regla de puntuación.
  Future<PlayerEventScoringRuleModel> createRule(
    PlayerEventScoringRuleModel rule,
  ) async {
    try {
      final response = await _supabase
          .from('player_event')
          .insert(rule.toJson())
          .select()
          .single();

      return PlayerEventScoringRuleModel.fromJson(response);
    } catch (e) {
      throw Exception('Error creating scoring rule: $e');
    }
  }

  /// Actualiza una regla existente.
  Future<PlayerEventScoringRuleModel> updateRule(
    PlayerEventScoringRuleModel rule,
  ) async {
    try {
      final response = await _supabase
          .from('player_event')
          .update(rule.toJson())
          .eq('id', rule.id)
          .select()
          .single();

      return PlayerEventScoringRuleModel.fromJson(response);
    } catch (e) {
      throw Exception('Error updating scoring rule: $e');
    }
  }

  /// Elimina una regla existente.
  Future<void> deleteRule(String ruleId) async {
    try {
      await _supabase.from('player_event').delete().eq('id', ruleId);
    } catch (e) {
      throw Exception('Error deleting scoring rule: $e');
    }
  }

  /// Upsert: crea o actualiza una regla.
  Future<PlayerEventScoringRuleModel> upsertRule(
    PlayerEventScoringRuleModel rule,
  ) async {
    try {
      final existing = await getRuleByTeamAndType(rule.teamId, rule.eventType);

      if (existing != null) {
        return updateRule(rule.copyWith(id: existing.id));
      } else {
        return createRule(rule);
      }
    } catch (e) {
      throw Exception('Error upserting scoring rule: $e');
    }
  }
}
