import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';

class AttendanceModel extends Attendance {
  const AttendanceModel({
    required super.id,
    required super.teamId,
    required super.playerId,
    required super.date,
    required super.attended,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: supabaseInt(json['id']) ?? 0,
      teamId: supabaseInt(json['team_id']) ?? 0,
      playerId: supabaseInt(json['player_id']) ?? 0,
      date: DateTime.tryParse('${json['date']}') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      attended: json['attended'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'player_id': playerId,
      'date': date.toIso8601String(),
      'attended': attended,
    };
  }

  AttendanceModel copyWith({
    int? id,
    int? teamId,
    int? playerId,
    DateTime? date,
    bool? attended,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      date: date ?? this.date,
      attended: attended ?? this.attended,
    );
  }
}
