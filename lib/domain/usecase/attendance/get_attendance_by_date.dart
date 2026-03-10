import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/attendance.dart';
import 'package:tfg1/domain/i_repositories/i_attendance_repository.dart';

class GetAttendanceByDate {
  final IAttendanceRepository _attendanceRepository;

  GetAttendanceByDate(this._attendanceRepository);

  Future<Either<Failure, List<Attendance>>> call(DateTime date) async {
    return await _attendanceRepository.getAttendancesByDate(date);
  }
}