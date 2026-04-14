import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/usecase/attendance/create_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendance_by_date_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/update_attendance_use_case.dart';
import 'package:football_manager/presentation/attendance/cubit/attendance_cubit.dart';
import 'package:football_manager/presentation/attendance/pages/attendance_page.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';
import 'package:football_manager/presentation/convocation/pages/convocation_page.dart';
import 'package:football_manager/presentation/match/pages/match_list_page.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
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

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: BottomAppBar(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: scheme.primary.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: buttons,
            ),
          ),
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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: scheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
