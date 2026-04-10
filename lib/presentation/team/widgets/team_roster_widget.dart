import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/add_new_player_use_case.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';
import 'package:football_manager/presentation/player/pages/add_player_page.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_state.dart';
import 'package:football_manager/presentation/team/widgets/team_players_list.dart';

class TeamRosterWidget extends StatelessWidget {
  final Team team;

  const TeamRosterWidget({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    bool isExternal = false;
    if (authState is Authenticated) {
      isExternal = authState.user.teamRoles[team.id] == UserRole.external;
    }

    final Widget playersWidget = isExternal
        ? _ExternalPlayersTable(team: team)
        : TeamPlayersList(team: team);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plantilla',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(child: playersWidget),
        const SizedBox(height: 12),
        if (!isExternal)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is! Authenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Debes iniciar sesión para añadir jugadores',
                      ),
                      backgroundColor: Colors.red,
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
              icon: const Icon(Icons.person_add),
              label: const Text('Añadir jugador'),
            ),
          ),
      ],
    );
  }
}

class _ExternalPlayersTable extends StatelessWidget {
  final Team team;

  const _ExternalPlayersTable({required this.team});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamDetailCubit, TeamDetailState>(
      builder: (context, state) {
        if (state is TeamDetailLoading || state is TeamDetailInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TeamDetailError) {
          return Center(child: Text(state.message));
        }
        if (state is TeamDetailLoaded) {
          if (state.players.isEmpty) {
            return const Center(
              child: Text('No hay jugadores en la plantilla'),
            );
          }

          final players = List.of(state.players)
            ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Dorsal')),
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Apellidos')),
              ],
              rows: players
                  .map(
                    (player) => DataRow(
                      cells: [
                        DataCell(Text(player.number?.toString() ?? '-')),
                        DataCell(Text(player.firstName)),
                        DataCell(Text(player.lastName ?? '')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
