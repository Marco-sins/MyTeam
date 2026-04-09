import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/i_repositories/i_attendance_repository.dart';

class GetAttendanceDaysByTeamUseCase {
  final IAttendanceRepository _attendanceRepository;

  GetAttendanceDaysByTeamUseCase(this._attendanceRepository);

  Future<Either<Failure, List<DateTime>>> call(int teamId) async {
    final response = await _attendanceRepository.getAttendances();
    return response.fold((failure) => Left(failure), (attendances) {
      final datesSet = <DateTime>{};
      for (final Attendance attendance in attendances) {
        if (attendance.teamId == teamId) {
          final dateOnly = DateTime(
            attendance.date.year,
            attendance.date.month,
            attendance.date.day,
          );
          datesSet.add(dateOnly);
        }
      }
      final dates = datesSet.toList()..sort((a, b) => b.compareTo(a));
      return Right(dates);
    });
  }
}
