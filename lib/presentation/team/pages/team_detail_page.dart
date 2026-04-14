import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/constants/app_branding.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/usecase/team/leave_team_as_external_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/home/cubit/home_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
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

class _TeamDetailPageState extends State<TeamDetailPage>
    with WidgetsBindingObserver {
  bool _accessVerified = false;
  bool _handledNoAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyTeamAccess());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyTeamAccess(fromResume: true);
    }
  }

  Future<void> _verifyTeamAccess({bool fromResume = false}) async {
    if (_handledNoAccess) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    try {
      final row = await Supabase.instance.client
          .from('team_members')
          .select('id_team')
          .eq('id_user', authState.user.id)
          .eq('id_team', widget.team.id)
          .maybeSingle();

      if (!mounted || _handledNoAccess) return;

      if (row == null) {
        _onNoLongerHasAccess();
        return;
      }

      if (!_accessVerified) {
        setState(() => _accessVerified = true);
      }
    } catch (_) {
      if (!mounted || _handledNoAccess) return;
      if (!fromResume && !_accessVerified) {
        setState(() => _accessVerified = true);
      }
    }
  }

  Future<void> _onNoLongerHasAccess() async {
    if (_handledNoAccess || !mounted) return;
    _handledNoAccess = true;
    WidgetsBinding.instance.removeObserver(this);

    context.read<HomeCubit>().fetchTeams();
    context.read<AuthCubit>().refreshAuthenticatedUser();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.lock_person_outlined,
            size: 40,
            color: scheme.error,
          ),
          title: const Text('Sin acceso al equipo'),
          content: const Text(
            'Ya no tienes acceso a este equipo. '
            'Se ha quitado de tu panel y no podrás volver a entrar hasta que un administrador te invite de nuevo.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmAndLeaveTeamAsExternal() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final scheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonar equipo'),
        content: Text(
          '¿Quieres salir de ${widget.team.name}? '
          'Dejarás de ver la plantilla y los partidos hasta que un administrador te vuelva a invitar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Salir del equipo'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final useCase = context.read<LeaveTeamAsExternalUseCase>();
    final result = await useCase(widget.team.id, authState.user);
    if (!mounted) return;

    await result.fold<Future<void>>(
      (failure) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: scheme.error,
          ),
        );
      },
      (_) async {
        await context.read<AuthCubit>().refreshAuthenticatedUser();
        if (!mounted) return;
        context.read<HomeCubit>().fetchTeams();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Has salido del equipo'),
            backgroundColor: scheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    bool isExternal = false;
    final authForHeader = context.watch<AuthCubit>().state;
    if (authForHeader is Authenticated) {
      isExternal =
          authForHeader.user.teamRoles[widget.team.id] == UserRole.external;
    }

    if (!_accessVerified) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppBranding.mainTitleEs),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Comprobando acceso…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppBranding.mainTitleEs),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TeamDetailHeader(
              team: widget.team,
              onLeaveTeam: isExternal ? _confirmAndLeaveTeamAsExternal : null,
            ),
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
