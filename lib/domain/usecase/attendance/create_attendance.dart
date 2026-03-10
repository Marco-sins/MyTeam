import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/attendance.dart';
import 'package:tfg1/domain/i_repositories/i_attendance_repository.dart';

class CreateAttendance {
  final IAttendanceRepository _attendanceRepository;

  CreateAttendance(this._attendanceRepository);

  Future<Either<Failure, void>> call(Attendance attendance) async {
    return await _attendanceRepository.createAttendance(attendance);
  }
}