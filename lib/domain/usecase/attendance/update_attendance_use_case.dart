import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/attendance.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/i_repositories/i_attendance_repository.dart';

class UpdateAttendanceUseCase {
  final IAttendanceRepository _attendanceRepository;

  UpdateAttendanceUseCase(this._attendanceRepository);

  Future<Either<Failure, void>> call(
    Attendance attendance,
    AuthUser user,
  ) async {
    if (user.teamRoles[attendance.teamId] != UserRole.admin) {
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
