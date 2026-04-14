import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/attendance/cubit/attendance_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_present_absent_counters.dart';

class AttendanceDateBar extends StatelessWidget {
  final String formattedDate;

  const AttendanceDateBar({super.key, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Icon(Icons.event_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                formattedDate,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () async {
              final attendanceState = context.read<AttendanceCubit>().state;
              final picked = await showDatePicker(
                context: context,
                initialDate: attendanceState.selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                final authState = context.read<AuthCubit>().state;
                final teamState = context.read<TeamDetailCubit>().state;
                if (authState is! Authenticated ||
                    teamState is! TeamDetailLoaded) {
                  return;
                }
                final players = List<Player>.from(teamState.players);
                await context.read<AttendanceCubit>().loadForDate(
 picked,
                      authState.user,
                      players,
                    );
              }
            },
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Cambiar fecha',
          ),
          const SizedBox(width: 4),
          const AttendancePresentAbsentCounters(),
        ],
      ),
    );
  }
}
