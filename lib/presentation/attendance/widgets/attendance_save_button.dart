import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/attendance/cubit/attendance_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';

class AttendanceSaveButton extends StatelessWidget {
  final Team team;

  const AttendanceSaveButton({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () async {
          final saving = context.read<AttendanceCubit>().state.saving;
          if (saving) return;

          final authState = context.read<AuthCubit>().state;
          if (authState is! Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Debes iniciar sesión para guardar la asistencia',
                ),
                backgroundColor: scheme.error,
              ),
            );
            return;
          }

          final teamState = context.read<TeamDetailCubit>().state;
          if (teamState is! TeamDetailLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'No se ha podido cargar la plantilla del equipo',
                ),
                backgroundColor: scheme.error,
              ),
            );
            return;
          }

          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              return Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: scheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Guardando…',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );

          final players = List<Player>.from(teamState.players)
            ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
          final cubit = context.read<AttendanceCubit>();
          final errorMessage = await cubit.saveAttendance(
            authState.user,
            players,
          );

          if (!context.mounted) return;

          Navigator.of(context, rootNavigator: true).pop();

          if (errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: scheme.error,
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Asistencia guardada correctamente'),
              backgroundColor: scheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          final getPlayersByTeamUseCase =
              context.read<GetPlayersByTeamUseCase>();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) =>
                    TeamDetailCubit(getPlayersByTeamUseCase)..loadTeam(team.id),
                child: TeamDetailPage(team: team),
              ),
            ),
            (route) => route.isFirst,
          );
        },
        icon: const Icon(Icons.save_rounded),
        label: const Text(
          'Guardar asistencia',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
