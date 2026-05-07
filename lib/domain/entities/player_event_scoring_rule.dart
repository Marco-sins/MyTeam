/// Entidad que representa una regla de puntuación de eventos de jugador.
/// Define cuántos puntos suma o resta un evento en la puntuación del jugador.
class PlayerEventScoringRule {
  final String id;
  final int teamId;
  final String eventType; // 'scoregoal', 'goodpass', etc
  final double points; // Puntos que suma o resta
  final bool enabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlayerEventScoringRule({
    required this.id,
    required this.teamId,
    required this.eventType,
    required this.points,
    required this.enabled,
    required this.createdAt,
    this.updatedAt,
  });

  PlayerEventScoringRule copyWith({
    String? id,
    int? teamId,
    String? eventType,
    double? points,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerEventScoringRule(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      eventType: eventType ?? this.eventType,
      points: points ?? this.points,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
