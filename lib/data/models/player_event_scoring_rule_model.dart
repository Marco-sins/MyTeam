/// Modelo persistible de PlayerEventScoringRule usado para mapear filas de la tabla
/// `player_event` a la entidad de dominio.
import 'package:football_manager/domain/entities/player_event_scoring_rule.dart';

class PlayerEventScoringRuleModel extends PlayerEventScoringRule {
  const PlayerEventScoringRuleModel({
    required super.id,
    required super.teamId,
    required super.eventType,
    required super.points,
    required super.enabled,
    required super.createdAt,
    super.updatedAt,
  });

  factory PlayerEventScoringRuleModel.fromJson(Map<String, dynamic> json) {
    return PlayerEventScoringRuleModel(
      id: json['id'] as String? ?? '',
      teamId: json['id_team'] as int? ?? 0,
      eventType: (json['event_type'] as String?)?.trim() ?? '',
      points: (json['point'] as num?)?.toDouble() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'id_team': teamId,
      'event_type': eventType,
      'point': points,
      'enabled': enabled,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  PlayerEventScoringRuleModel copyWith({
    String? id,
    int? teamId,
    String? eventType,
    double? points,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerEventScoringRuleModel(
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
