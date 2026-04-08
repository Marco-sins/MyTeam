import 'package:tfg1/data/models/match_lineup_model.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/match.dart';

class MatchModel extends Match {
  const MatchModel({
    required super.id,
    required super.teamId,
    required super.opponent,
    required super.goalsScored,
    required super.goalsConceded,
    required super.date,
    required super.hour,
    required super.status,
    required super.lineups,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final rawLineups = json['lineups'];
    final List<MatchLineupModel> parsedLineups;

    if (rawLineups is List) {
      parsedLineups = rawLineups
          .map((lineupJson) => MatchLineupModel.fromJson(lineupJson))
          .toList();
    } else {
      // Si no viene el campo lineups en la consulta (select solo sobre matches),
      // usamos una lista vacía.
      parsedLineups = const [];
    }

    final parsedDate = DateTime.parse(json['date']);
    final rawHour = json['hour'];
    final String parsedHour;
    if (rawHour is String && rawHour.isNotEmpty) {
      parsedHour = rawHour;
    } else {
      final h = parsedDate.hour.toString().padLeft(2, '0');
      final m = parsedDate.minute.toString().padLeft(2, '0');
      parsedHour = '$h:$m';
    }

    return MatchModel(
      id: json['id'],
      teamId: json['team_id'],
      opponent: json['opponent'],
      goalsScored: json['goals_scored'],
      goalsConceded: json['goals_conceded'],
      date: parsedDate,
      hour: parsedHour,
      status: MatchStatus.values.firstWhere(
        (e) => e.toString() == 'MatchStatus.${json['status']}',
      ),
      lineups: parsedLineups,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'opponent': opponent,
      'goals_scored': goalsScored,
      'goals_conceded': goalsConceded,
      'date': date.toIso8601String(),
      'hour': hour,
      'status': status
          .toString()
          .split('.')
          .last, // Store only the enum value as a string
    };
  }

  MatchModel copyWith({
    int? id,
    int? teamId,
    String? opponent,
    int? goalsScored,
    int? goalsConceded,
    DateTime? date,
    String? hour,
    MatchStatus? status,
    List<MatchLineupModel>? lineups,
  }) {
    return MatchModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      opponent: opponent ?? this.opponent,
      goalsScored: goalsScored ?? this.goalsScored,
      goalsConceded: goalsConceded ?? this.goalsConceded,
      date: date ?? this.date,
      hour: hour ?? this.hour,
      status: status ?? this.status,
      lineups: lineups ?? this.lineups,
    );
  }
}
