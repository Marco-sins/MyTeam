/// Modelo para la tabla `attendance` con serialización a la entidad de dominio
/// `Attendance`.
import 'package:football_manager/domain/entities/attendance.dart';

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
      id: json['id'],
      teamId: json['team_id'],
      playerId: json['player_id'],
      date: DateTime.parse(json['date']),
      attended: json['attended'],
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
