import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/presentation/attendance/bloc/attendance_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';
import 'package:tfg1/presentation/attendance/widgets/attendance_present_absent_counters.dart';

class AttendanceDateBar extends StatelessWidget {
  final String formattedDate;

  const AttendanceDateBar({super.key, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.calendar_today),
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
          ),
          const Spacer(),
          const AttendancePresentAbsentCounters(),
        ],
      ),
    );
  }
}
