import 'package:dartz/dartz.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/domain/entities/attendance.dart';

abstract class IAttendanceRepository {
  Future<Either<Failure, List<Attendance>>> getAttendances();
  Future<Either<Failure, Attendance>> getAttendanceById(int id);
  Future<Either<Failure, Unit>> createAttendance(Attendance attendance);
  Future<Either<Failure, Unit>> updateAttendance(Attendance attendance);
  Future<Either<Failure, Unit>> deleteAttendance(int id);
  Future<Either<Failure, List<Attendance>>> getAttendancesByDate(DateTime date);
}