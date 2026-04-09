import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/permission_failure.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/i_repositories/i_attendance_repository.dart';

class DeleteAttendanceDayUseCase {
  final IAttendanceRepository _attendanceRepository;

  DeleteAttendanceDayUseCase(this._attendanceRepository);

  Future<Either<Failure, void>> call(
    DateTime date,
    int teamId,
    AuthUser user,
  ) async {
    if (user.teamRoles[teamId] != UserRole.admin) {
      return Left(
        PermissionFailure(
          'You do not have permission to delete this attendance.',
        ),
      );
    }

    final response = await _attendanceRepository.getAttendancesByDate(
      date,
      teamId,
    );

    return response.fold((failure) => Left(failure), (attendances) async {
      for (final attendance in attendances) {
        final deleteResponse = await _attendanceRepository.deleteAttendance(
          attendance.id,
        );
        if (deleteResponse.isLeft()) {
          return deleteResponse.map((_) {});
        }
      }
      return const Right(null);
    });
  }
}
