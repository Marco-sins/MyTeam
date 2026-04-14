import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/attendance/models/attendance_status.dart';
import 'package:football_manager/presentation/attendance/cubit/attendance_cubit.dart';
import 'package:football_manager/presentation/attendance/cubit/attendance_state.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';

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
    final scheme = Theme.of(context).colorScheme;
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
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniBadge(
              context,
              icon: Icons.check_circle_outline,
              count: present,
              bg: scheme.primaryContainer,
              fg: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            _miniBadge(
              context,
              icon: Icons.cancel_outlined,
              count: absent,
              bg: scheme.errorContainer,
              fg: scheme.onErrorContainer,
            ),
          ],
        );
      },
    );
  }

  Widget _miniBadge(
    BuildContext context, {
    required IconData icon,
    required int count,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: fg,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
