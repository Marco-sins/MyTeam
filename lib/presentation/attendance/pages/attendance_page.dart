import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/core/utils/attendance_date_format.dart';
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
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/team_session_routes.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

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
    final formattedDate = attendanceFormatDateWithWeekday(
      context,
      attendanceState.selectedDate,
    );
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return TeamBrandedScope(
      team: team,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.screenAttendance),
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
          actions: const [TeamQuickNavAppBarButton()],
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              sliver: SliverToBoxAdapter(child: AttendanceHeader(team: team)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverFillRemaining(
                hasScrollBody: true,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AttendanceDateBar(formattedDate: formattedDate),
                              const AttendanceTableHeader(),
                            ],
                          ),
                        ),
                      ),
                      Expanded(flex: 5, child: AttendancePlayerList()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: scheme.surface,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: constraints.maxWidth),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.attendanceSaveHint,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              const AttendanceSaveButton(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const TeamBottomBar(),
          ],
        ),
      ),
    );
  }
}
