import 'package:equatable/equatable.dart';
import 'package:football_manager/presentation/attendance/attendance_status.dart';

class AttendanceState extends Equatable {
  final DateTime selectedDate;
  final Map<int, AttendanceStatus> statuses;
  final bool loading;
  final bool saving;
  final String? error;

  const AttendanceState({
    required this.selectedDate,
    required this.statuses,
    this.loading = false,
    this.saving = false,
    this.error,
  });

  factory AttendanceState.initial(DateTime date) {
    return AttendanceState(
      selectedDate: date,
      statuses: const {},
      loading: false,
      saving: false,
      error: null,
    );
  }

  AttendanceState copyWith({
    DateTime? selectedDate,
    Map<int, AttendanceStatus>? statuses,
    bool? loading,
    bool? saving,
    String? error,
  }) {
    return AttendanceState(
      selectedDate: selectedDate ?? this.selectedDate,
      statuses: statuses ?? this.statuses,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: error,
    );
  }

  @override
  List<Object?> get props => [selectedDate, statuses, loading, saving, error];
}
