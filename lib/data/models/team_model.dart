/// Modelo persistible de `Team` usado para mapear filas de la tabla `teams`
/// a la entidad de dominio. Provee `fromJson` y `toJson`.
library;

import 'package:football_manager/domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.name,
    required super.category,
    super.logoUrl,
    super.color,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      logoUrl: json['logo_url'],
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'logo_url': logoUrl,
      'color': color,
    };
  }

  TeamModel copyWith({
    int? id,
    String? name,
    String? category,
    String? logoUrl,
    String? color,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      color: color ?? this.color,
    );
  }
}
