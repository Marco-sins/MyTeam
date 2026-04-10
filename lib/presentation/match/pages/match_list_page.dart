import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/common/loading_cubit.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/pages/match_stats_page.dart';
import 'package:football_manager/presentation/match/pages/match_manager_page.dart';
import 'package:football_manager/presentation/team/bloc/team_detail_cubit.dart';
import 'package:football_manager/presentation/team/pages/team_detail_page.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';

class MatchListPage extends StatefulWidget {
  final Team team;

  const MatchListPage({super.key, required this.team});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  late Future<dynamic> _matchesFuture;
  Timer? _timer;

  // Marcador "en vivo" calculado desde match_events
  final Map<int, int> _liveGoalsScored = {};
  final Map<int, int> _liveGoalsConceded = {};

  @override
  void initState() {
    super.initState();
    _loadMatches();
    // Actualizamos la UI cada segundo para que el tiempo transcurrido
    // de los partidos en juego se vea en tiempo real.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadMatches() {
    _matchesFuture = context.read<GetMatchesByTeamUseCase>().call(
      widget.team.id,
    );
    // Limpiamos los marcadores en vivo para recargarlos
    _liveGoalsScored.clear();
    _liveGoalsConceded.clear();
  }

  String _statusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.notStarted:
        return 'Pendiente';
      case MatchStatus.firstHalf:
        return '1ª parte';
      case MatchStatus.halfTime:
        return 'Half time';
      case MatchStatus.secondHalf:
        return '2ª parte';
      case MatchStatus.finished:
        return 'Finalizado';
    }
  }

  String _elapsedText(Match match) {
    // Solo mostramos el timer en 1ª y 2ª parte; en descanso no.
    if (match.status != MatchStatus.firstHalf &&
        match.status != MatchStatus.secondHalf) {
      return '-';
    }

    final now = DateTime.now();
    final diff = now.difference(match.date).inSeconds;
    if (diff <= 0) return '0:00';

    final minutes = (diff ~/ 60).toString();
    final seconds = (diff % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _ensureLiveScoresLoaded(List<Match> matches) async {
    final supabase = Supabase.instance.client;

    for (final match in matches) {
      // Si ya tenemos marcador calculado, no lo volvemos a pedir
      if (_liveGoalsScored.containsKey(match.id) &&
          _liveGoalsConceded.containsKey(match.id)) {
        continue;
      }

      try {
        final result = await supabase
            .from('match_events')
            .select('type')
            .eq('match_id', match.id);

        int scored = 0;
        int conceded = 0;

        for (final row in result) {
          final raw = row['type'];
          if (raw == null) continue;
          final typeString = raw.toString().split('.').last;

          if (typeString == 'scoreGoal') {
            scored++;
          } else if (typeString == 'concedeGoal' || typeString == 'ownGoal') {
            conceded++;
          }
        }

        if (!mounted) return;
        setState(() {
          _liveGoalsScored[match.id] = scored;
          _liveGoalsConceded[match.id] = conceded;
        });
      } catch (_) {
        // Si falla, simplemente dejamos el marcador de la entidad Match
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidos'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final getPlayersByTeamUseCase = context
                .read<GetPlayersByTeamUseCase>();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) =>
                      TeamDetailCubit(getPlayersByTeamUseCase)
                        ..loadTeam(widget.team.id),
                  child: TeamDetailPage(team: widget.team),
                ),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),
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

              // Cargar marcadores en vivo desde match_events (no bloquea la UI)
              _ensureLiveScoresLoaded(matches);

              return ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final dateText =
                      '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';
                  final liveScored = _liveGoalsScored[match.id];
                  final liveConceded = _liveGoalsConceded[match.id];
                  final scoreText =
                      '${liveScored ?? match.goalsScored} - ${liveConceded ?? match.goalsConceded}';
                  final elapsed = _elapsedText(match);
                  final statusText = _statusText(match.status);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
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
                        } else if (match.status == MatchStatus.firstHalf ||
                            match.status == MatchStatus.halfTime ||
                            match.status == MatchStatus.secondHalf) {
                          // Reentrar en un partido ya iniciado (en juego o descanso)
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
                          final getPlayersByTeamUseCase = context
                              .read<GetPlayersByTeamUseCase>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (ctx) => MatchStatsCubit(
                                  match: match,
                                  getPlayersByTeamUseCase:
                                      getPlayersByTeamUseCase,
                                )..load(),
                                child: MatchStatsPage(match: match),
                              ),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fecha y hora a la izquierda
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // Estado + tiempo a la derecha
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      statusText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      elapsed,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Mi equipo vs rival centrado
                            Center(
                              child: Text(
                                '${widget.team.name}  vs  ${match.opponent}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Resultado grande abajo
                            Center(
                              child: Text(
                                scoreText,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
