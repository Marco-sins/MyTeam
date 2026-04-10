import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/usecase/attendance/create_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendance_by_date_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/update_attendance_use_case.dart';
import 'package:football_manager/presentation/attendance/bloc/attendance_cubit.dart';
import 'package:football_manager/presentation/attendance/pages/attendance_page.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';
import 'package:football_manager/presentation/common/loading_cubit.dart';
import 'package:football_manager/presentation/convocation/pages/convocation_page.dart';
import 'package:football_manager/presentation/match/pages/match_list_page.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/pages/team_management_page.dart';

class TeamBottomBar extends StatelessWidget {
  final Team team;

  const TeamBottomBar({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    bool isExternal = false;
    if (authState is Authenticated) {
      isExternal = authState.user.teamRoles[team.id] == UserRole.external;
    }

    final List<Widget> buttons = [];

    if (!isExternal) {
      buttons.addAll([
        _BottomBarButton(
          label: 'Asistencia',
          icon: Icons.check_circle_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<TeamDetailCubit>()),
                    BlocProvider<AttendanceCubit>(
                      create: (ctx) => AttendanceCubit(
                        ctx.read<GetAttendanceByDateUseCase>(),
                        ctx.read<CreateAttendanceUseCase>(),
                        ctx.read<UpdateAttendanceUseCase>(),
                        initialDate: DateTime.now(),
                        teamId: team.id,
                      ),
                    ),
                  ],
                  child: AttendancePage(team: team),
                ),
              ),
            );
          },
        ),
        _BottomBarButton(
          label: 'Convocatoria',
          icon: Icons.list_alt,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<TeamDetailCubit>()),
                    BlocProvider<LoadingCubit>(create: (_) => LoadingCubit()),
                  ],
                  child: ConvocationPage(team: team),
                ),
              ),
            );
          },
        ),
      ]);
    }

    // El apartado de partidos siempre está disponible
    buttons.add(
      _BottomBarButton(
        label: 'Partido',
        icon: Icons.sports_soccer,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<TeamDetailCubit>(),
                child: MatchListPage(team: team),
              ),
            ),
          );
        },
      ),
    );

    if (!isExternal) {
      buttons.add(
        _BottomBarButton(
          label: 'Gestión',
          icon: Icons.settings,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<TeamDetailCubit>(),
                  child: TeamManagementPage(team: team),
                ),
              ),
            );
          },
        ),
      );
    }

    return BottomAppBar(
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: buttons,
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _BottomBarButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
