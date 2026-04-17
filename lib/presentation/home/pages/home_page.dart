import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:football_manager/domain/usecase/invitation/get_invitations_by_email_use_case.dart';
import 'package:football_manager/presentation/home/widgets/add_team.dart';
import 'package:football_manager/presentation/invitations/pages/invitations_page.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/pages/login_page.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_empty.dart';
import '../widgets/team_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _invitationsCount = 0;
  RealtimeChannel? _teamMembersChannel;
  RealtimeChannel? _invitationsChannel;
  AppLifecycleState? _previousAppLifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<HomeCubit>().fetchTeams();
    _loadInvitationsCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeTeamMembersRealtime();
      _subscribeInvitationsRealtime();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final chTeam = _teamMembersChannel;
    _teamMembersChannel = null;
    if (chTeam != null) {
      unawaited(Supabase.instance.client.removeChannel(chTeam));
    }
    final chInv = _invitationsChannel;
    _invitationsChannel = null;
    if (chInv != null) {
      unawaited(Supabase.instance.client.removeChannel(chInv));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prev = _previousAppLifecycle;
    _previousAppLifecycle = state;
    // Evita refrescos en cada cambio menor de foco; solo al volver de segundo plano.
    if (state == AppLifecycleState.resumed &&
        (prev == AppLifecycleState.paused ||
            prev == AppLifecycleState.hidden)) {
      unawaited(_refreshHome());
    }
  }

  /// Si te quitan de un equipo, el panel se actualiza sin reiniciar la app.
  /// Requiere Realtime activado para `team_members` en Supabase (recomendado).
  void _subscribeTeamMembersRealtime() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final uid = authState.user.id;

    _teamMembersChannel = Supabase.instance.client
        .channel('team_members_panel_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'team_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_user',
            value: uid,
          ),
          callback: (_) {
            if (!mounted) return;
            context.read<HomeCubit>().fetchTeams();
            context.read<AuthCubit>().refreshAuthenticatedUser();
          },
        )
        .subscribe();
  }

  /// Actualiza el contador del botón al instante cuando llega o se borra una invitación.
  /// Requiere Realtime activado para la tabla `invitation` en Supabase.
  void _subscribeInvitationsRealtime() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final inboxEmail = authState.user.email.trim().toLowerCase();
    if (inboxEmail.isEmpty) return;

    final channelId =
        'inv_inbox_${inboxEmail.hashCode}_${authState.user.id.hashCode}';

    _invitationsChannel = Supabase.instance.client
        .channel(channelId)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invitation',
          callback: (payload) {
            String? rowEmail;
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                rowEmail = payload.newRecord['email']?.toString();
                break;
              case PostgresChangeEvent.update:
                rowEmail =
                    payload.newRecord['email']?.toString() ??
                    payload.oldRecord['email']?.toString();
                break;
              case PostgresChangeEvent.delete:
                rowEmail = payload.oldRecord['email']?.toString();
                break;
              case PostgresChangeEvent.all:
                return;
            }
            if (rowEmail == null) return;
            if (rowEmail.trim().toLowerCase() != inboxEmail) return;
            if (!mounted) return;
            _loadInvitationsCount();
          },
        )
        .subscribe();
  }

  Future<void> _loadInvitationsCount() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      if (mounted) {
        setState(() {
          _invitationsCount = 0;
        });
      }
      return;
    }

    try {
      final getInvitationsByEmailUseCase = context
          .read<GetInvitationsByEmailUseCase>();
      final normalizedEmail = authState.user.email.trim().toLowerCase();
      final result = await getInvitationsByEmailUseCase(normalizedEmail);

      if (!mounted) return;

      result.fold(
        (_) {
          setState(() {
            _invitationsCount = 0;
          });
        },
        (invitations) {
          setState(() {
            _invitationsCount = invitations.length;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _invitationsCount = 0;
      });
    }
  }

  Future<void> _refreshHome() async {
    await context.read<HomeCubit>().fetchTeams();
    await _loadInvitationsCount();
  }

  int _crossAxisCountForWidth(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  Widget _pullToRefreshWrapper({required Widget child}) {
    return RefreshIndicator(onRefresh: _refreshHome, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: const HomeAppBar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'invitations',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvitationsPage(),
                        ),
                      );
                      if (!mounted) return;
                      _loadInvitationsCount();
                    },
                    elevation: 1,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                    icon: const Icon(Icons.forward_to_inbox_rounded, size: 22),
                    label: Text(AppLocalizations.of(context)!.homeInvitations),
                  ),
                  if (_invitationsCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _invitationsCount > 9 ? '9+' : '$_invitationsCount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onError,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              const AddTeam(),
            ],
          ),
        ),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final width = MediaQuery.sizeOf(context).width;
            final crossAxisCount = _crossAxisCountForWidth(width);

            if (state is HomeLoading || state is HomeInitial) {
              final l10n = AppLocalizations.of(context)!;
              return _pullToRefreshWrapper(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scheme = Theme.of(context).colorScheme;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 36,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        l10n.homeLoadingTeams,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            if (state is HomeError) {
              final l10n = AppLocalizations.of(context)!;
              return _pullToRefreshWrapper(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scheme = Theme.of(context).colorScheme;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.cloud_off_outlined,
                                        size: 44,
                                        color: scheme.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        state.message,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 20),
                                      FilledButton.tonalIcon(
                                        onPressed: _refreshHome,
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: Text(l10n.homeRetry),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            if (state is HomeLoaded) {
              if (state.teams.isEmpty) {
                return _pullToRefreshWrapper(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: const HomeEmpty(),
                        ),
                      );
                    },
                  ),
                );
              }

              return _pullToRefreshWrapper(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HomeIntroHeader(teamCount: state.teams.length),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        108 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 206,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return TeamCard(team: state.teams[index]);
                        }, childCount: state.teams.length),
                      ),
                    ),
                  ],
                ),
              );
            }

            return _pullToRefreshWrapper(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeIntroHeader extends StatelessWidget {
  const _HomeIntroHeader({required this.teamCount});

  final int teamCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final countLine = teamCount == 1
        ? l10n.homeTeamCountOne
        : l10n.homeTeamCountMany(teamCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_outlined, size: 22, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.homeYourPanel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            countLine,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
