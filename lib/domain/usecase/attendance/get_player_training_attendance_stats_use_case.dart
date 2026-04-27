import 'package:dartz/dartz.dart';
import 'package:football_manager/domain/failures/failure.dart';
import 'package:football_manager/domain/repositories/i_attendance_repository.dart';

class GetPlayerTrainingAttendanceStatsUseCase {
  GetPlayerTrainingAttendanceStatsUseCase(this._attendanceRepository);

  final IAttendanceRepository _attendanceRepository;

  Future<Either<Failure, ({int total, int attended})>> call({
    required int teamId,
    required int playerId,
  }) {
    return _attendanceRepository.getPlayerAttendanceStats(
      teamId: teamId,
      playerId: playerId,
    );
  }
}
