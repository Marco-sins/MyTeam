import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/i_repositories/i_attendance_repository.dart';

class GetAttendancesUseCase {
  final IAttendanceRepository _attendanceRepository;

  GetAttendancesUseCase(this._attendanceRepository);

  Future<Either<Failure, List<Attendance>>> call() {
    return _attendanceRepository.getAttendances();
  }
}
