import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _HomePageState extends State<HomePage> {
  int _invitationsCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().fetchTeams();
    _loadInvitationsCount();
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
      final result = await getInvitationsByEmailUseCase(authState.user.email);

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
    return RefreshIndicator(
      onRefresh: _refreshHome,
      child: child,
    );
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
        floatingActionButton: Row(
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
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  icon: const Icon(Icons.forward_to_inbox_rounded, size: 22),
                  label: const Text('Invitaciones'),
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
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final width = MediaQuery.sizeOf(context).width;
            final crossAxisCount = _crossAxisCountForWidth(width);

            if (state is HomeLoading || state is HomeInitial) {
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
                                        'Cargando tus equipos…',
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      const SizedBox(height: 20),
                                      FilledButton.tonalIcon(
                                        onPressed: _refreshHome,
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: const Text('Reintentar'),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 206,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return TeamCard(team: state.teams[index]);
                          },
                          childCount: state.teams.length,
                        ),
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

    final countLine = teamCount == 1
        ? 'Tienes 1 equipo. Toca una tarjeta para abrirlo.'
        : 'Tienes $teamCount equipos. Toca una tarjeta para abrirlo.';

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
                  'Tu panel',
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
