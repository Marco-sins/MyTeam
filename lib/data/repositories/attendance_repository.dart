import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/core/errors/failure/server_failure.dart';
import 'package:football_manager/core/errors/failure/unknow_failure.dart';
import 'package:football_manager/data/datasource/attendance_remote_datasource.dart';
import 'package:football_manager/data/mappers/attendance_mapper.dart';
import 'package:football_manager/data/models/attendance_model.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/repositories/i_attendance_repository.dart';

class AttendanceRepository implements IAttendanceRepository {
  final AttendanceRemoteDatasource _remoteDatasource;

  AttendanceRepository(this._remoteDatasource);

  @override
  Future<Either<Failure, Unit>> createAttendance(Attendance attendance) async {
    try {
      AttendanceModel attendanceModel = AttendanceMapper.toModel(attendance);
      await _remoteDatasource.createAttendance(attendanceModel);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAttendance(int id) async {
    try {
      await _remoteDatasource.deleteAttendance(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Attendance>> getAttendanceById(int id) async {
    try {
      final response = await _remoteDatasource.getAttendanceById(id);
      Attendance attendance = AttendanceMapper.toEntity(response);
      return Right(attendance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAttendances() async {
    try {
      final result = await _remoteDatasource.getAttendances();
      List<Attendance> attendances = result
          .map((e) => AttendanceMapper.toEntity(e))
          .toList();
      return Right(attendances);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAttendancesByDate(
    DateTime date,
    int teamId,
  ) async {
    try {
      final result = await _remoteDatasource.getAttendancesByDate(date, teamId);
      List<Attendance> attendances = result
          .map((e) => AttendanceMapper.toEntity(e))
          .toList();
      return Right(attendances);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAttendance(Attendance attendance) async {
    try {
      await _remoteDatasource.updateAttendance(
        AttendanceMapper.toModel(attendance),
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on UnknowException catch (e) {
      return Left(UnknowFailure(e.message));
    }
  }
}
