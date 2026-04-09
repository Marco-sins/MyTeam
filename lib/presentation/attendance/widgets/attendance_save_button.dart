import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/attendance/bloc/attendance_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';
import 'package:tfg1/presentation/team/pages/team_detail_page.dart';

class AttendanceSaveButton extends StatelessWidget {
  final Team team;

  const AttendanceSaveButton({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Evitamos dobles clics si ya se está guardando
          final saving = context.read<AttendanceCubit>().state.saving;
          if (saving) return;

          final authState = context.read<AuthCubit>().state;
          if (authState is! Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Debes iniciar sesión para guardar la asistencia',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final teamState = context.read<TeamDetailCubit>().state;
          if (teamState is! TeamDetailLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se ha podido cargar la plantilla del equipo'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Modal de cargando mientras se procesa el guardado
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              return const Center(child: CircularProgressIndicator());
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

          // Cerramos el diálogo de cargando antes de mostrar el resultado
          Navigator.of(context, rootNavigator: true).pop();

          if (errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asistencia guardada correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Volvemos siempre al home del equipo
          final getPlayersByTeamUseCase = context
              .read<GetPlayersByTeamUseCase>();
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
        icon: const Icon(Icons.save),
        label: const Text(
          'Guardar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
