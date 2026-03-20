import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/permission_failure.dart';
import 'package:tfg1/domain/entities/attendance.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/enum/user_role.dart';
import 'package:tfg1/domain/i_repositories/i_attendance_repository.dart';

class CreateAttendanceUseCase {
  final IAttendanceRepository _attendanceRepository;

  CreateAttendanceUseCase(this._attendanceRepository);

  Future<Either<Failure, void>> call(
    Attendance attendance,
    AuthUser user,
  ) async {
    if (user.teamRoles[attendance.teamId] != UserRole.admin) {
      return Left(PermissionFailure('User does not have a role in the team'));
    }
    final response = await _attendanceRepository.createAttendance(attendance);
    if (response.isLeft()) {
      return response;
    }
    return Right(null);
  }
}
