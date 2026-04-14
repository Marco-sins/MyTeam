import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/attendance/models/attendance_status.dart';
import 'package:football_manager/presentation/attendance/cubit/attendance_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_player_row.dart';

class AttendancePlayerList extends StatelessWidget {
  const AttendancePlayerList({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final attendanceState = context.watch<AttendanceCubit>().state;

    return BlocBuilder<TeamDetailCubit, TeamDetailState>(
      builder: (context, state) {
        if (state is TeamDetailLoading || state is TeamDetailInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TeamDetailError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
            ),
          );
        }
        if (state is TeamDetailLoaded) {
          final players = List<Player>.from(state.players)
            ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

          if (players.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 48,
                      color: scheme.outline.withValues(alpha: 0.65),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay jugadores en la plantilla',
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: players.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            itemBuilder: (context, index) {
              final player = players[index];
              final currentStatus = attendanceState.statuses[player.id] ??
                  AttendanceStatus.present;

              return AttendancePlayerRow(
                player: player,
                currentStatus: currentStatus,
                onMarkPresent: () => context
                    .read<AttendanceCubit>()
                    .setStatus(player.id, AttendanceStatus.present),
                onMarkAbsent: () => context.read<AttendanceCubit>().setStatus(
                      player.id,
                      AttendanceStatus.absent,
                    ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
