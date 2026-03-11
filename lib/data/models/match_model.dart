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
    required super.status, 
    required super.lineups,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      teamId: json['teamId'],
      opponent: json['opponent'],
      goalsScored: json['goalsScored'],
      goalsConceded: json['goalsConceded'],
      date: DateTime.parse(json['date']),
      status: MatchStatus.values.firstWhere((e) => e.toString() == 'MatchStatus.${json['status']}'),
      lineups: (json['lineups'] as List).map((lineupJson) => MatchLineupModel.fromJson(lineupJson)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'opponent': opponent,
      'goalsScored': goalsScored,
      'goalsConceded': goalsConceded,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last, // Store only the enum value as a string
      'lineups': lineups.map((lineup) => (lineup as MatchLineupModel).toJson()).toList(),
    };
  }
}