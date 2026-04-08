import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/player/add_new_player_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/player/pages/add_player_page.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/widgets/team_players_list.dart';

class TeamRosterWidget extends StatelessWidget {
  final Team team;

  const TeamRosterWidget({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plantilla',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(child: TeamPlayersList(team: team)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              final authState = context.read<AuthCubit>().state;
              if (authState is! Authenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes iniciar sesión para añadir jugadores'),
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
