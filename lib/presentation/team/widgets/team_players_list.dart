import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/player/delete_player_use_case.dart';
import 'package:tfg1/domain/usecase/player/update_player_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/player/pages/edit_player_page.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';

class TeamPlayersList extends StatelessWidget {
  final Team team;

  const TeamPlayersList({super.key, required this.team});

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
          return ListView.separated(
            itemCount: players.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                title: Text(
                  '${player.number?.toString() ?? '-'}  ${player.fullName}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        final authState = context.read<AuthCubit>().state;
                        if (authState is! Authenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Debes iniciar sesión para editar jugadores',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final updatePlayerUseCase = context
                            .read<UpdatePlayerUseCase>();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditPlayerPage(
                              team: team,
                              player: player,
                              currentUser: authState.user,
                              updatePlayerUseCase: updatePlayerUseCase,
                            ),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<TeamDetailCubit>().loadTeam(team.id);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final authState = context.read<AuthCubit>().state;
                        if (authState is! Authenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Debes iniciar sesión para borrar jugadores',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Borrar jugador'),
                            content: Text(
                              '¿Seguro que quieres borrar a ${player.fullName}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text(
                                  'Borrar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        final deletePlayerUseCase = context
                            .read<DeletePlayerUseCase>();
                        final result = await deletePlayerUseCase(
                          player,
                          authState.user,
                        );

                        result.fold(
                          (failure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(failure.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Jugador borrado correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.read<TeamDetailCubit>().loadTeam(team.id);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
