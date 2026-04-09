import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match/delete_match_use_case.dart';
import 'package:football_manager/presentation/auth/bloc/auth_cubit.dart';
import 'package:football_manager/presentation/auth/bloc/auth_state.dart';

class MatchDeletePage extends StatefulWidget {
  final Team team;

  const MatchDeletePage({super.key, required this.team});

  @override
  State<MatchDeletePage> createState() => _MatchDeletePageState();
}

class _MatchDeletePageState extends State<MatchDeletePage> {
  late Future<dynamic> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    _matchesFuture = context.read<GetMatchesByTeamUseCase>().call(
      widget.team.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar partido'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: _matchesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('No se han podido cargar los partidos'),
              );
            }

            final either = snapshot.data!;
            return either.fold((failure) => Center(child: Text(failure.message)), (
              matches,
            ) {
              if (matches.isEmpty) {
                return const Center(
                  child: Text('No hay partidos para este equipo'),
                );
              }

              return ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final statusText = () {
                    switch (match.status) {
                      case MatchStatus.notStarted:
                        return 'Pendiente';
                      case MatchStatus.firstHalf:
                        return '1ª parte';
                      case MatchStatus.halfTime:
                        return 'Descanso';
                      case MatchStatus.secondHalf:
                        return '2ª parte';
                      case MatchStatus.finished:
                        return 'Finalizado';
                    }
                  }();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(match.opponent),
                      subtitle: Text(
                        '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')} · $statusText',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          final authState = context.read<AuthCubit>().state;
                          if (authState is! Authenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Debes iniciar sesión para borrar partidos',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar partido'),
                              content: Text(
                                '¿Seguro que quieres eliminar el partido contra ${match.opponent}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final deleteMatchUseCase = context
                              .read<DeleteMatchUseCase>();
                          final result = await deleteMatchUseCase(
                            match,
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
                                  content: Text(
                                    'Partido eliminado correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Recargamos la lista de partidos
                              setState(_loadMatches);
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            });
          },
        ),
      ),
    );
  }
}
