import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/team/widgets/team_detail_header.dart';
import 'package:football_manager/presentation/team/widgets/team_attendance_section.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';
import 'package:football_manager/presentation/team/widgets/team_roster_widget.dart';

class TeamDetailPage extends StatefulWidget {
  final Team team;

  const TeamDetailPage({super.key, required this.team});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi equipo'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TeamDetailHeader(team: widget.team),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: BlocBuilder<TeamDetailCubit, TeamDetailState>(
                builder: (context, state) {
                  if (state is TeamDetailLoading || state is TeamDetailInitial) {
                    return Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: scheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Cargando plantilla…',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (state is TeamDetailError) {
                    return Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_outlined,
                                size: 48,
                                color: scheme.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.message,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (state is TeamDetailLoaded) {
                    if (state.players.isEmpty) {
                      return Center(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.group_off_outlined,
                                  size: 56,
                                  color:
                                      scheme.outline.withValues(alpha: 0.65),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aún no hay jugadores en la plantilla',
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Añádelos desde Gestión → Modificar plantilla.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final authState = context.read<AuthCubit>().state;
                    bool isExternal = false;
                    if (authState is Authenticated) {
                      isExternal =
                          authState.user.teamRoles[widget.team.id] ==
                              UserRole.external;
                    }

                    if (isExternal) {
                      return TeamRosterWidget(team: widget.team);
                    }

                    return TeamAttendanceSection(
                      team: widget.team,
                      players: state.players,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TeamBottomBar(team: widget.team),
    );
  }
}
