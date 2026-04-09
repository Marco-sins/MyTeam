import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/presentation/attendance/attendance_status.dart';
import 'package:football_manager/presentation/attendance/bloc/attendance_cubit.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_state.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_player_row.dart';

class AttendancePlayerList extends StatelessWidget {
  const AttendancePlayerList({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceState = context.watch<AttendanceCubit>().state;

    return Expanded(
      child: BlocBuilder<TeamDetailCubit, TeamDetailState>(
        builder: (context, state) {
          if (state is TeamDetailLoading || state is TeamDetailInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TeamDetailError) {
            return Center(child: Text(state.message));
          }
          if (state is TeamDetailLoaded) {
            final players = List<Player>.from(state.players)
              ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

            if (players.isEmpty) {
              return const Center(
                child: Text('No hay jugadores en la plantilla'),
              );
            }

            return ListView.separated(
              itemCount: players.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final player = players[index];
                final currentStatus =
                    attendanceState.statuses[player.id] ??
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
      ),
    );
  }
}
