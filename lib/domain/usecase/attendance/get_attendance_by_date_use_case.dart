import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/repositories/i_attendance_repository.dart';

class GetAttendanceByDateUseCase {
  final IAttendanceRepository _attendanceRepository;

  GetAttendanceByDateUseCase(this._attendanceRepository);

  Future<Either<Failure, List<Attendance>>> call(
    DateTime date,
    AuthUser user,
    int teamId,
  ) async {
    final teamRole = user.teamRoles[teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure(
          'You do not have permission to view this attendance.',
        ),
      );
    }
    final response = await _attendanceRepository.getAttendancesByDate(
      date,
      teamId,
    );
    if (response.isLeft()) {
      return response;
    }
    return Right(response.getOrElse(() => []));
  }
}
