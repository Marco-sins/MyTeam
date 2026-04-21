import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/core/utils/attendance_date_format.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/attendance/delete_attendance_day_use_case.dart';
import 'package:football_manager/domain/usecase/attendance/get_attendance_days_by_team_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/team_session_routes.dart';
import 'package:football_manager/presentation/team/widgets/team_area_background.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

class AttendanceDeletePage extends StatefulWidget {
  final Team team;

  const AttendanceDeletePage({super.key, required this.team});

  @override
  State<AttendanceDeletePage> createState() => _AttendanceDeletePageState();
}

class _AttendanceDeletePageState extends State<AttendanceDeletePage> {
  late Future<dynamic> _daysFuture;

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  void _loadDays() {
    _daysFuture = context.read<GetAttendanceDaysByTeamUseCase>().call(
      widget.team.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamContextCubit>().state;
    return TeamBrandedScope(
      team: team,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.screenDeleteAttendance),
          centerTitle: true,
          actions: const [TeamQuickNavAppBarButton()],
        ),
        body: SafeArea(
          top: false,
          child: TeamAreaBackground(
            team: team,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder(
                future: _daysFuture,
                builder: (context, snapshot) {
                  final l10n = AppLocalizations.of(context)!;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData) {
                    return Center(child: Text(l10n.attendanceDeleteLoadError));
                  }

                  final either = snapshot.data!;
                  return either.fold(
                    (failure) => Center(child: Text(failure.message)),
                    (dates) {
                      if (dates.isEmpty) {
                        return Center(child: Text(l10n.attendanceDeleteEmpty));
                      }

                      return ListView.builder(
                        itemCount: dates.length,
                        itemBuilder: (context, index) {
                          final date = dates[index] as DateTime;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(
                                attendanceFormatDateWithFullWeekday(
                                  context,
                                  date,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final authState = context
                                      .read<AuthCubit>()
                                      .state;
                                  if (authState is! Authenticated) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.attendanceDeleteNeedLogin,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) {
                                      final dlgL10n = AppLocalizations.of(
                                        context,
                                      )!;
                                      return AlertDialog(
                                        title: Text(
                                          dlgL10n.screenDeleteAttendance,
                                        ),
                                        content: Text(
                                          dlgL10n.attendanceDeleteConfirmBody(
                                            attendanceFormatDateWithFullWeekday(
                                              context,
                                              date,
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: Text(dlgL10n.actionCancel),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: Text(
                                              dlgL10n.actionRemove,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirm != true) return;

                                  // Modal de cargando mientras se elimina la asistencia
                                  showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  final deleteAttendanceDayUseCase = context
                                      .read<DeleteAttendanceDayUseCase>();
                                  final result =
                                      await deleteAttendanceDayUseCase(
                                        date,
                                        team.id,
                                        authState.user,
                                      );

                                  result.fold(
                                    (failure) {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(failure.message),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    },
                                    (_) {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Asistencia del día eliminada correctamente',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );

                                      Navigator.of(context).pushAndRemoveUntil(
                                        TeamSessionRoutes.detailHomeReplacingStack(
                                          context,
                                        ),
                                        (route) => route.isFirst,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
