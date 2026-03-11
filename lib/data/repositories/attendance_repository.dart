import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/exception/supabase_exception_handler.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/data/models/attendance_model.dart';
import 'package:tfg1/domain/entities/attendance.dart';
import 'package:tfg1/domain/i_repositories/i_attendance_repository.dart';

class AttendanceRepository implements IAttendanceRepository {
  final SupabaseClient _supabase;

  AttendanceRepository(this._supabase);

  @override
  Future<Either<Failure, Unit>> createAttendance(Attendance attendance) async {
    try {
      await _supabase.from('attendances').insert({
        'team_id': attendance.teamId,
        'player_id': attendance.playerId,
        'date': attendance.date.toIso8601String(),
        'attended': attendance.attended,
      });
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAttendance(int id) async {
    try {
      await _supabase.from('attendances').delete().eq('id', id);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Attendance>> getAttendanceById(int id) async {
    try {
      final result = await _supabase
          .from('attendances')
          .select()
          .eq('id', id)
          .single();
      Attendance attendance = AttendanceModel.fromJson(result);
      return Right(attendance);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAttendances() async {
    try {
      final result = await _supabase.from('attendances').select();
      List<Attendance> attendances = result
          .map((e) => AttendanceModel.fromJson(e))
          .toList();
      return Right(attendances);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAttendancesByDate(
    DateTime date,
  ) async {
    try {
      final result = await _supabase
          .from('attendances')
          .select()
          .eq('date', date.toIso8601String());
      List<Attendance> attendances = result
          .map((e) => AttendanceModel.fromJson(e))
          .toList();
      return Right(attendances);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAttendance(Attendance attendance) async {
    try {
      await _supabase
          .from('attendances')
          .update({
            'team_id': attendance.teamId,
            'player_id': attendance.playerId,
            'date': attendance.date.toIso8601String(),
            'attended': attendance.attended,
          })
          .eq('id', attendance.id);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptionHandler.handleException(e));
    } on AuthException catch (e) {
      return Left(ServerFailure('Authentication error: $e'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
