import 'package:tfg1/domain/entities/attendance.dart';

abstract class IAttendanceRepository {
  Future<List<Attendance>> getAttendances();
  Future<Attendance> getAttendanceById(int id);
  Future<void> addAttendance(Attendance attendance);
  Future<void> updateAttendance(Attendance attendance);
  Future<void> deleteAttendance(int id);
  Future<List<Attendance>> getAttendancesByDate(DateTime date);
}