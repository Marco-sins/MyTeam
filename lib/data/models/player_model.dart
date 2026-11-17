import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/data/models/player_stats_model.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/entities/player.dart';

class PlayerModel extends Player {
  const PlayerModel({
    required super.id,
    required super.teamId,
    required super.firstName,
    super.lastName,
    super.number,
    super.phone,
    super.email,
    super.imgUrl,
    super.positions,
    PlayerStatsModel? super.stats,
    int? super.anioNacimiento,
  });

  static String? _optionalString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final rawPositions = json['positions']?.toString();
    List<PlayerPosition> positions = [];
    if (rawPositions != null && rawPositions.trim().isNotEmpty) {
      positions = rawPositions.split(',').map((rawPosition) {
        final value = rawPosition.trim();
        if (value.isEmpty) return null;
        for (final position in PlayerPosition.values) {
          if (position.name == value) return position;
        }
        return null;
      }).whereType<PlayerPosition>().toList();
    }

    final rawImg = json['img_url'];
    final String? imgUrl = rawImg == null
        ? null
        : rawImg.toString().trim().isEmpty
        ? null
        : rawImg.toString().trim();

    return PlayerModel(
      id: supabaseInt(json['id']) ?? 0,
      teamId: supabaseInt(json['team_id']) ?? 0,
      firstName:
          (json['firstname'] ?? json['firstName'])?.toString().trim() ?? '',
      lastName: _optionalString(json['lastname'] ?? json['lastName']),
      number: supabaseInt(json['number']),
      phone: _optionalString(json['phone']),
      email: _optionalString(json['email']),
      imgUrl: imgUrl,
      positions: positions,
      stats: _statsFromEmbed(json['stats'] ?? json['player_stats']),
      anioNacimiento: supabaseInt(json['anio_nacimiento']),
    );
  }

  static PlayerStatsModel? _statsFromEmbed(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      if (raw.isEmpty) return null;
      final first = raw.first;
      if (first is Map<String, dynamic>) {
        return PlayerStatsModel.fromJson(first);
      }
      if (first is Map) {
        return PlayerStatsModel.fromJson(Map<String, dynamic>.from(first));
      }
      return null;
    }
    if (raw is Map<String, dynamic>) {
      return PlayerStatsModel.fromJson(raw);
    }
    if (raw is Map) {
      return PlayerStatsModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final String? positionsString = positions == null || positions!.isEmpty
        ? null
        : positions!
              .map((position) => position.toString().split('.').last)
              .join(',');

    final map = <String, dynamic>{
      'team_id': teamId,
      'firstname': firstName,
      'lastname': lastName,
      'number': number,
      'phone': phone,
      'email': email,
      'positions': positionsString,
      'img_url': imgUrl,
      'anio_nacimiento': anioNacimiento,
    };

    return map;
  }

  PlayerModel copyWith({
    int? id,
    int? teamId,
    String? firstName,
    String? lastName,
    int? number,
    String? phone,
    String? email,
    String? imgUrl,
    List<PlayerPosition>? positions,
    PlayerStatsModel? stats,
    int? anioNacimiento,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      number: number ?? this.number,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      imgUrl: imgUrl ?? this.imgUrl,
      positions: positions ?? this.positions,
      stats: stats ?? this.stats as PlayerStatsModel?,
      anioNacimiento: anioNacimiento ?? this.anioNacimiento,
    );
  }
}
