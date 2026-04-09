import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/attendance_model.dart';

class AttendanceRemoteDatasource {
  final SupabaseClient _supabase;

  AttendanceRemoteDatasource(this._supabase);

  Future<void> createAttendance(AttendanceModel attendanceData) async {
    try {
      final response = await _supabase
          .from('attendances')
          .insert(attendanceData.toJson())
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Failed to create attendance',
          code: '500',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> deleteAttendance(int id) async {
    try {
      final response = await _supabase
          .from('attendances')
          .delete()
          .eq('id', id)
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Attendance with id $id not found',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<AttendanceModel> getAttendanceById(int id) async {
    try {
      final result = await _supabase
          .from('attendances')
          .select()
          .eq('id', id)
          .single();
      return AttendanceModel.fromJson(result);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<AttendanceModel>> getAttendances() async {
    try {
      final result = await _supabase.from('attendances').select();
      return result.map((e) => AttendanceModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<AttendanceModel>> getAttendancesByDate(
    DateTime date,
    int teamId,
  ) async {
    try {
      final result = await _supabase
          .from('attendances')
          .select()
          .eq('date', date.toIso8601String())
          .eq('team_id', teamId);
      return result.map((e) => AttendanceModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updateAttendance(AttendanceModel attendance) async {
    try {
      final response = await _supabase
          .from('attendances')
          .update(attendance.toJson())
          .eq('id', attendance.id)
          .select();
      if (response.isEmpty) {
        throw ServerException(
          message: 'Attendance with id ${attendance.id} not found',
          code: '404',
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }
}
