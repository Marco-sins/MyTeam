/// Mapeador entre la fila `attendance` y la entidad de dominio `Attendance`.
library;

import 'package:football_manager/data/models/attendance_model.dart';
import 'package:football_manager/domain/entities/attendance.dart';

class AttendanceMapper {
  static AttendanceModel toModel(Attendance attendance) {
    return AttendanceModel(
      id: attendance.id,
      teamId: attendance.teamId,
      playerId: attendance.playerId,
      date: attendance.date,
      attended: attendance.attended,
    );
  }

  static Attendance toEntity(AttendanceModel attendanceModel) {
    return Attendance(
      id: attendanceModel.id,
      teamId: attendanceModel.teamId,
      playerId: attendanceModel.playerId,
      date: attendanceModel.date,
      attended: attendanceModel.attended,
    );
  }
}
