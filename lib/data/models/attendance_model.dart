import 'package:tfg1/domain/entities/attendance.dart';

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
      teamId: json['teamId'],
      playerId: json['playerId'],
      date: DateTime.parse(json['date']),
      attended: json['attended'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'playerId': playerId,
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
