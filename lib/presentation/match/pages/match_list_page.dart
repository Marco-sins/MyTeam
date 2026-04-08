import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:tfg1/presentation/common/loading_cubit.dart';
import 'package:tfg1/presentation/match/pages/match_stats_page.dart';
import 'package:tfg1/presentation/match/pages/match_manager_page.dart';
import 'package:tfg1/presentation/team/widgets/team_bottom_bar.dart';

class MatchListPage extends StatefulWidget {
  final Team team;

  const MatchListPage({super.key, required this.team});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
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

  String _statusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.notStarted:
        return 'Pendiente';
      case MatchStatus.inProgress:
        return 'En juego';
      case MatchStatus.paused:
        return 'Pausado';
      case MatchStatus.finished:
        return 'Finalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partidos'), centerTitle: true),
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
              List<Match> matches,
            ) {
              if (matches.isEmpty) {
                return const Center(
                  child: Text('No hay partidos para este equipo'),
                );
              }

              matches.sort((Match a, Match b) => b.date.compareTo(a.date));

              return ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final dateText =
                      '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';
                  final scoreText =
                      '${match.goalsScored} - ${match.goalsConceded}';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(match.opponent),
                      subtitle: Text(
                        '$dateText · ${_statusText(match.status)}',
                      ),
                      trailing: Text(
                        scoreText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () async {
                        if (match.status == MatchStatus.notStarted) {
                          // Entrar al gestor sin empezar todavía el partido
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => LoadingCubit(),
                                child: MatchManagerPage(
                                  team: widget.team,
                                  match: match,
                                ),
                              ),
                            ),
                          ).then((_) {
                            if (mounted) {
                              setState(_loadMatches);
                            }
                          });
                        } else if (match.status == MatchStatus.inProgress ||
                            match.status == MatchStatus.paused) {
                          // Reentrar en un partido ya iniciado (en juego o pausado)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => LoadingCubit(),
                                child: MatchManagerPage(
                                  team: widget.team,
                                  match: match,
                                ),
                              ),
                            ),
                          ).then((_) {
                            if (mounted) {
                              setState(_loadMatches);
                            }
                          });
                        } else if (match.status == MatchStatus.finished) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MatchStatsPage(match: match),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            });
          },
        ),
      ),
      bottomNavigationBar: TeamBottomBar(team: widget.team),
    );
  }
}
