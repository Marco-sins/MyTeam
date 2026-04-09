import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/attendance.dart';
import 'package:tfg1/domain/entities/auth_user.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/usecase/attendance/create_attendance_use_case.dart';
import 'package:tfg1/domain/usecase/attendance/get_attendance_by_date_use_case.dart';
import 'package:tfg1/domain/usecase/attendance/update_attendance_use_case.dart';
import 'package:tfg1/presentation/attendance/attendance_status.dart';

import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final GetAttendanceByDateUseCase _getAttendanceByDateUseCase;
  final CreateAttendanceUseCase _createAttendanceUseCase;
  final UpdateAttendanceUseCase _updateAttendanceUseCase;
  final int teamId;

  AttendanceCubit(
    this._getAttendanceByDateUseCase,
    this._createAttendanceUseCase,
    this._updateAttendanceUseCase, {
    required DateTime initialDate,
    required this.teamId,
  }) : super(AttendanceState.initial(initialDate));

  Future<void> loadForDate(
    DateTime date,
    AuthUser user,
    List<Player> players,
  ) async {
    emit(state.copyWith(selectedDate: date, loading: true, error: null));

    final result = await _getAttendanceByDateUseCase(date, user, teamId);

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null);
      emit(state.copyWith(loading: false, error: failure?.message));
      return;
    }

    final list = result.getOrElse(() => <Attendance>[]);

    if (list.isEmpty) {
      // Sin registros ese día: dejamos el mapa vacío (por defecto presentes).
      emit(state.copyWith(statuses: {}, loading: false, error: null));
      return;
    }

    final existingByPlayer = <int, Attendance>{
      for (final a in list) a.playerId: a,
    };

    final newStatuses = <int, AttendanceStatus>{};

    for (final p in players) {
      final existing = existingByPlayer[p.id];
      if (existing == null) {
        newStatuses[p.id] = AttendanceStatus.absent;
      } else {
        newStatuses[p.id] = existing.attended
            ? AttendanceStatus.present
            : AttendanceStatus.absent;
      }
    }

    emit(state.copyWith(statuses: newStatuses, loading: false, error: null));
  }

  void setStatus(int playerId, AttendanceStatus status) {
    final updated = Map<int, AttendanceStatus>.from(state.statuses);
    updated[playerId] = status;
    emit(state.copyWith(statuses: updated));
  }

  Future<String?> saveAttendance(AuthUser user, List<Player> players) async {
    emit(state.copyWith(saving: true, error: null));

    final existingResult = await _getAttendanceByDateUseCase(
      state.selectedDate,
      user,
      teamId,
    );

    if (existingResult.isLeft()) {
      final failure = existingResult.fold((f) => f, (_) => null);
      emit(state.copyWith(saving: false, error: failure?.message));
      return failure?.message;
    }

    final existingList = existingResult.getOrElse(() => <Attendance>[]);
    final existingByPlayer = <int, Attendance>{
      for (final a in existingList) a.playerId: a,
    };

    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

    for (final player in sortedPlayers) {
      final status = state.statuses[player.id] ?? AttendanceStatus.present;
      final attended = status != AttendanceStatus.absent;
      final existing = existingByPlayer[player.id];

      if (existing == null) {
        final newAttendance = Attendance(
          id: 0,
          teamId: teamId,
          playerId: player.id,
          date: state.selectedDate,
          attended: attended,
        );
        final res = await _createAttendanceUseCase(newAttendance, user);
        if (res.isLeft()) {
          final failure = res.fold((f) => f, (_) => null);
          emit(state.copyWith(saving: false, error: failure?.message));
          return failure?.message;
        }
      } else {
        if (existing.attended == attended) continue;
        final updated = Attendance(
          id: existing.id,
          teamId: existing.teamId,
          playerId: existing.playerId,
          date: state.selectedDate,
          attended: attended,
        );
        final res = await _updateAttendanceUseCase(updated, user);
        if (res.isLeft()) {
          final failure = res.fold((f) => f, (_) => null);
          emit(state.copyWith(saving: false, error: failure?.message));
          return failure?.message;
        }
      }
    }

    emit(state.copyWith(saving: false, error: null));
    return null;
  }
}
