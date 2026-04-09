import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/attendance/attendance_status.dart';
import 'package:football_manager/presentation/attendance/bloc/attendance_cubit.dart';
import 'package:football_manager/presentation/attendance/bloc/attendance_state.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_state.dart';

class AttendancePresentAbsentCounters extends StatelessWidget {
  const AttendancePresentAbsentCounters({super.key});

  int _presentCount(List<Player> players, AttendanceState state) {
    if (players.isEmpty) return 0;
    int present = 0;
    for (final p in players) {
      final status = state.statuses[p.id] ?? AttendanceStatus.present;
      if (status == AttendanceStatus.present) {
        present++;
      }
    }
    return present;
  }

  int _absentCount(List<Player> players, AttendanceState state) {
    if (players.isEmpty) return 0;
    int absent = 0;
    for (final p in players) {
      final status = state.statuses[p.id] ?? AttendanceStatus.present;
      if (status == AttendanceStatus.absent) {
        absent++;
      }
    }
    return absent;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = context.watch<AttendanceCubit>().state;

    return BlocBuilder<TeamDetailCubit, TeamDetailState>(
      builder: (context, state) {
        if (state is! TeamDetailLoaded) {
          return const SizedBox.shrink();
        }
        final players = List<Player>.from(state.players);
        final present = _presentCount(players, attendanceState);
        final absent = _absentCount(players, attendanceState);
        return Row(
          children: [
            Text(
              '$present',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$absent',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}
