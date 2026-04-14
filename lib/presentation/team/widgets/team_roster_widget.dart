import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/add_new_player_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/player/pages/add_player_page.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_state.dart';
import 'package:football_manager/presentation/team/widgets/team_players_list.dart';

class TeamRosterWidget extends StatelessWidget {
  final Team team;

  const TeamRosterWidget({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authState = context.read<AuthCubit>().state;
    bool isExternal = false;
    if (authState is Authenticated) {
      isExternal =
          authState.user.teamRoles[team.id] == UserRole.external;
    }

    final Widget playersWidget = isExternal
        ? _ExternalPlayersTable(team: team)
        : TeamPlayersList(team: team);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Plantilla',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
          ),
        ),
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: playersWidget,
          ),
        ),
        if (!isExternal) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is! Authenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Debes iniciar sesión para añadir jugadores',
                      ),
                      backgroundColor: scheme.error,
                    ),
                  );
                  return;
                }

                final addNewPlayerUseCase = context.read<AddNewPlayerUseCase>();

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPlayerPage(
                      team: team,
                      currentUser: authState.user,
                      addNewPlayerUseCase: addNewPlayerUseCase,
                    ),
                  ),
                );

                if (!context.mounted) return;
                context.read<TeamDetailCubit>().loadTeam(team.id);
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Añadir jugador'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExternalPlayersTable extends StatelessWidget {
  final Team team;

  const _ExternalPlayersTable({required this.team});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<TeamDetailCubit, TeamDetailState>(
      builder: (context, state) {
        if (state is TeamDetailLoading || state is TeamDetailInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TeamDetailError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
            ),
          );
        }
        if (state is TeamDetailLoaded) {
          if (state.players.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 48,
                      color: scheme.outline.withValues(alpha: 0.65),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay jugadores en la plantilla',
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final players = List.of(state.players)
            ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: players.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(
                    player.number?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                title: Text(
                  player.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: player.lastName != null && player.lastName!.isEmpty
                    ? null
                    : null,
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
