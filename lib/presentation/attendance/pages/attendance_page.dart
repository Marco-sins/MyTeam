import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/attendance/cubit/attendance_cubit.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_date_bar.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_header.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_player_list.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_table_header.dart';
import 'package:football_manager/presentation/attendance/widgets/attendance_save_button.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/team/team_session_routes.dart';

/// Requiere [TeamContextCubit] en el árbol.
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  @override
  void initState() {
    super.initState();
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
    final team = context.watch<TeamContextCubit>().state;
    final attendanceState = context.watch<AttendanceCubit>().state;
    final formattedDate = _formattedDate(attendanceState.selectedDate);
    final scheme = Theme.of(context).colorScheme;

    return TeamBrandedScope(
      team: team,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              TeamSessionRoutes.detailHomeReplacingStack(context),
              (route) => route.isFirst,
            );
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AttendanceHeader(team: team),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AttendanceDateBar(formattedDate: formattedDate),
                    const AttendanceTableHeader(),
                    Expanded(
                      child: AttendancePlayerList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marca A (asiste) o X (falta) y guarda el día seleccionado.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              const AttendanceSaveButton(),
            ],
          ),
        ),
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
