import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/usecase/attendance/create_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendance_by_date_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/update_attendance_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/attendance/cubit/attendance_cubit.dart';
import 'package:football_manager/presentation/attendance/pages/attendance_page.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';
import 'package:football_manager/presentation/convocation/pages/convocation_page.dart';
import 'package:football_manager/presentation/match/pages/match_list_page.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/pages/team_management_page.dart';
import 'package:football_manager/presentation/team/team_session_routes.dart';

/// Navegación compartida entre la barra inferior del equipo y el menú rápido.
abstract final class TeamSessionNavigation {
  static void popToAppHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void goToTeamHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      TeamSessionRoutes.detailHomeReplacingStack(context),
      (route) => route.isFirst,
    );
  }

  static bool isExternalMember(BuildContext context, int teamId) {
    final auth = context.read<AuthCubit>().state;
    if (auth is! Authenticated) return false;
    return auth.user.teamRoles[teamId] == UserRole.external;
  }

  static Widget _shellWithDetail(
    BuildContext context, {
    required int teamId,
    List<BlocProvider> extraProviders = const <BlocProvider>[],
    required Widget child,
  }) {
    final teamContext = context.read<TeamContextCubit>();
    TeamDetailCubit? existing;
    try {
      existing = context.read<TeamDetailCubit>();
    } catch (_) {
      existing = null;
    }
    if (existing != null) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: teamContext),
          BlocProvider.value(value: existing),
          ...extraProviders,
        ],
        child: child,
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: teamContext),
        BlocProvider(
          create: (c) =>
              TeamDetailCubit(c.read<GetPlayersByTeamUseCase>())
                ..loadTeam(teamId),
        ),
        ...extraProviders,
      ],
      child: child,
    );
  }

  static void openAttendance(BuildContext context) {
    final team = context.read<TeamContextCubit>().state;
    if (isExternalMember(context, team.id)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _shellWithDetail(
          context,
          teamId: team.id,
          extraProviders: <BlocProvider>[
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
          child: const AttendancePage(),
        ),
      ),
    );
  }

  static void openConvocation(BuildContext context) {
    final team = context.read<TeamContextCubit>().state;
    if (isExternalMember(context, team.id)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _shellWithDetail(
          context,
          teamId: team.id,
          extraProviders: <BlocProvider>[
            BlocProvider<LoadingCubit>(create: (_) => LoadingCubit()),
          ],
          child: const ConvocationPage(),
        ),
      ),
    );
  }

  static void openMatchList(BuildContext context) {
    final team = context.read<TeamContextCubit>().state;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _shellWithDetail(
          context,
          teamId: team.id,
          child: const MatchListPage(),
        ),
      ),
    );
  }

  static void openManagement(BuildContext context) {
    final team = context.read<TeamContextCubit>().state;
    if (isExternalMember(context, team.id)) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _shellWithDetail(
          context,
          teamId: team.id,
          child: const TeamManagementPage(),
        ),
      ),
    );
  }
}
