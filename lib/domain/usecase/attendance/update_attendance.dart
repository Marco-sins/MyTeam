import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/attendance.dart';
import 'package:tfg1/domain/i_repositories/i_attendance_repository.dart';

class UpdateAttendance {
  final IAttendanceRepository _attendanceRepository;

  UpdateAttendance(this._attendanceRepository);

  Future<Either<Failure, void>> call(Attendance attendance) async {
    return await _attendanceRepository.updateAttendance(attendance);
  }
}