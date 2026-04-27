import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/utils/repository_guard.dart';
import 'package:football_manager/data/datasource/attendance_remote_datasource.dart';
import 'package:football_manager/data/mappers/attendance_mapper.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/repositories/i_attendance_repository.dart';

class AttendanceRepository implements IAttendanceRepository {
  final AttendanceRemoteDatasource _remoteDatasource;

  AttendanceRepository(this._remoteDatasource);

  @override
  Future<Either<Failure, Unit>> createAttendance(Attendance attendance) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.createAttendance(
        AttendanceMapper.toModel(attendance),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteAttendance(int id) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.deleteAttendance(id);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Attendance>> getAttendanceById(int id) {
    return runRepositoryGuard(() async {
      final response = await _remoteDatasource.getAttendanceById(id);
      return AttendanceMapper.toEntity(response);
    });
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAttendances() {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getAttendances();
      return result.map(AttendanceMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAttendancesByDate(
    DateTime date,
    int teamId,
  ) {
    return runRepositoryGuard(() async {
      final result = await _remoteDatasource.getAttendancesByDate(date, teamId);
      return result.map(AttendanceMapper.toEntity).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> updateAttendance(Attendance attendance) {
    return runRepositoryGuard(() async {
      await _remoteDatasource.updateAttendance(
        AttendanceMapper.toModel(attendance),
      );
      return unit;
    });
  }
}
