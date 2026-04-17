import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/repositories/i_attendance_repository.dart';

class UpdateAttendanceUseCase {
  final IAttendanceRepository _attendanceRepository;

  UpdateAttendanceUseCase(this._attendanceRepository);

  Future<Either<Failure, void>> call(
    Attendance attendance,
    AuthUser user,
  ) async {
    final teamRole = user.teamRoles[attendance.teamId];
    if (teamRole == null || !teamRole.hasAdminPrivileges) {
      return Left(
        PermissionFailure(
          'You do not have permission to update this attendance.',
        ),
      );
    }
    final response = await _attendanceRepository.updateAttendance(attendance);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
