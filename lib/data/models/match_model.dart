import 'package:football_manager/data/models/match_lineup_model.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';

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
    required super.isHome,
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

    // Si existe columna "hour" (timestamp), derivamos la hora desde ahí;
    // si no, usamos el campo "date" como respaldo.
    final rawHour = json['hour'];
    DateTime? hourDateTime;
    if (rawHour is String && rawHour.isNotEmpty) {
      try {
        hourDateTime = DateTime.parse(rawHour);
      } catch (_) {
        hourDateTime = null;
      }
    }

    final timeSource = hourDateTime ?? parsedDate;
    // Combinamos la fecha (día) con la hora proveniente de "hour" para que
    // el DateTime completo tenga la hora correcta.
    final combinedDateTime = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      timeSource.hour,
      timeSource.minute,
      timeSource.second,
    );

    final h = combinedDateTime.hour.toString().padLeft(2, '0');
    final m = combinedDateTime.minute.toString().padLeft(2, '0');
    final String parsedHour = '$h:$m';

    final bool parsedIsHome = (json['is_home'] as bool?) ?? true;

    return MatchModel(
      id: json['id'],
      teamId: json['team_id'],
      opponent: json['opponent'],
      goalsScored: json['goals_scored'],
      goalsConceded: json['goals_conceded'],
      date: combinedDateTime,
      hour: parsedHour,
      status: MatchStatus.values.firstWhere(
        (e) => e.toString() == 'MatchStatus.${json['status']}',
      ),
      lineups: parsedLineups,
      isHome: parsedIsHome,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'opponent': opponent,
      'goals_scored': goalsScored,
      'goals_conceded': goalsConceded,
      'date': date.toIso8601String(),
      // Guardamos la hora como timestamp completo para que encaje
      // con una columna "timestamp with time zone" en la BD.
      'hour': date.toIso8601String(),
      'status': status
          .toString()
          .split('.')
          .last, // Store only the enum value as a string
      'is_home': isHome,
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
    bool? isHome,
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
      isHome: isHome ?? this.isHome,
    );
  }
}
