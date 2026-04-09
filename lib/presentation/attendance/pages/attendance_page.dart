import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/attendance/bloc/attendance_cubit.dart';
import 'package:tfg1/presentation/attendance/widgets/attendance_date_bar.dart';
import 'package:tfg1/presentation/attendance/widgets/attendance_header.dart';
import 'package:tfg1/presentation/attendance/widgets/attendance_player_list.dart';
import 'package:tfg1/presentation/attendance/widgets/attendance_table_header.dart';
import 'package:tfg1/presentation/attendance/widgets/attendance_save_button.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';
import 'package:tfg1/presentation/team/pages/team_detail_page.dart';

class AttendancePage extends StatefulWidget {
  final Team team;

  const AttendancePage({super.key, required this.team});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  @override
  void initState() {
    super.initState();
    // Cargamos la asistencia existente para la fecha inicial (hoy)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = context.read<AuthCubit>().state;
      final teamState = context.read<TeamDetailCubit>().state;
      if (authState is! Authenticated || teamState is! TeamDetailLoaded) {
        return;
      }
      await context.read<AttendanceCubit>().loadForDate(
        context.read<AttendanceCubit>().state.selectedDate,
        authState.user,
        List.from(teamState.players),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = context.watch<AttendanceCubit>().state;
    final String formattedDate = _formattedDate(attendanceState.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final getPlayersByTeamUseCase = context
                .read<GetPlayersByTeamUseCase>();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) =>
                      TeamDetailCubit(getPlayersByTeamUseCase)
                        ..loadTeam(widget.team.id),
                  child: TeamDetailPage(team: widget.team),
                ),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttendanceHeader(team: widget.team),
          AttendanceDateBar(formattedDate: formattedDate),
          const AttendanceTableHeader(),
          const AttendancePlayerList(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AttendanceSaveButton(team: widget.team),
        ),
      ),
    );
  }

  String _formattedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}
