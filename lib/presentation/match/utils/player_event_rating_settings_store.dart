import 'package:football_manager/domain/entities/player_event_scoring_rule.dart';

/// Regla de puntuación legible por la UI (contiene label + key).
/// Se usa internamente en la UI después de sincronizar desde Supabase.
class PlayerEventRatingRule {
  final String key; // event_type de la BD
  final String label;
  final double points;
  final bool enabled;
  final String? dbId; // ID de la fila en la BD

  const PlayerEventRatingRule({
    required this.key,
    required this.label,
    required this.points,
    required this.enabled,
    this.dbId,
  });

  PlayerEventRatingRule copyWith({
    String? key,
    String? label,
    double? points,
    bool? enabled,
    String? dbId,
  }) {
    return PlayerEventRatingRule(
      key: key ?? this.key,
      label: label ?? this.label,
      points: points ?? this.points,
      enabled: enabled ?? this.enabled,
      dbId: dbId ?? this.dbId,
    );
  }

  factory PlayerEventRatingRule.fromEntity(
    PlayerEventScoringRule entity,
    String label,
  ) {
    return PlayerEventRatingRule(
      key: entity.eventType,
      label: label,
      points: entity.points,
      enabled: entity.enabled,
      dbId: entity.id,
    );
  }

  PlayerEventScoringRule toEntity(int teamId) {
    return PlayerEventScoringRule(
      id: dbId ?? '',
      teamId: teamId,
      eventType: key,
      points: points,
      enabled: enabled,
      createdAt: DateTime.now(),
    );
  }
}

/// Store singleton que mantiene en memoria las reglas de puntuación.
/// Se sincroniza con Supabase a través del repositorio.
class PlayerEventRatingSettingsStore {
  PlayerEventRatingSettingsStore._();

  static final PlayerEventRatingSettingsStore instance =
      PlayerEventRatingSettingsStore._();

  List<PlayerEventRatingRule> _rules = defaultRules();

  List<PlayerEventRatingRule> get rules => List.unmodifiable(_rules);

  /// Carga las reglas para un equipo desde memoria o valores por defecto.
  void setRulesForTeam(int teamId, List<PlayerEventRatingRule> rules) {
    _rules = List<PlayerEventRatingRule>.from(rules);
  }

  /// Obtiene la puntuación para un tipo de evento.
  double pointsForKey(String key) {
    final rule = ruleForKey(key);
    if (rule == null || !rule.enabled) return 0;
    return rule.points;
  }

  /// Encuentra una regla por su clave (event_type).
  PlayerEventRatingRule? ruleForKey(String key) {
    final normalized = key.trim().toLowerCase();
    for (final rule in _rules) {
      if (rule.key.toLowerCase() == normalized) {
        return rule;
      }
    }
    return null;
  }

  /// Establece los valores por defecto.
  void resetToDefaults() {
    _rules = defaultRules();
  }

  static List<PlayerEventRatingRule> defaultRules() {
    return const [
      PlayerEventRatingRule(
        key: 'scoregoal',
        label: 'Gol',
        points: 1.0,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'assist',
        label: 'Asistencia',
        points: 0.75,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'shot',
        label: 'Tiro',
        points: 0.2,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'goodpass',
        label: 'Buen pase',
        points: 0.1,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'goodplay',
        label: 'Buena jugada',
        points: 0.3,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'badplay',
        label: 'Mala jugada',
        points: 0.3,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'badpass',
        label: 'Mal pase',
        points: -0.1,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'cantada',
        label: 'Cantada',
        points: -1.0,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'foul',
        label: 'Falta',
        points: -0.4,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'yellowcard',
        label: 'Tarjeta amarilla',
        points: -0.8,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'redcard',
        label: 'Tarjeta roja',
        points: -2.5,
        enabled: true,
      ),
      PlayerEventRatingRule(
        key: 'offside',
        label: 'Fuera de juego',
        points: -0.2,
        enabled: true,
      ),
    ];
  }
}
