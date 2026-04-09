import 'package:football_manager/domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.name,
    required super.category,
    super.logoUrl,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'category': category, 'logo_url': logoUrl};
  }

  TeamModel copyWith({
    int? id,
    String? name,
    String? category,
    String? logoUrl,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
