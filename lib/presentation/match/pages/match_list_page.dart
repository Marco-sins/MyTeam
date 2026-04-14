import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/pages/match_stats_page.dart';
import 'package:football_manager/presentation/match/pages/match_manager_page.dart';
import 'package:football_manager/presentation/team/cubit/team_detail_cubit.dart';
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

  /// Evita planificar varias veces el mismo fetch desde el build del FutureBuilder.
  String? _liveScoresScheduleKey;

  // Marcador "en vivo" calculado desde match_events
  final Map<int, int> _liveGoalsScored = {};
  final Map<int, int> _liveGoalsConceded = {};

  bool _isThisRouteVisible() {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    // Si no hay ruta o hay otra encima (p. ej. gestor de partido), no
    // reconstruimos: evita asserts de semántica/layout en la ruta inferior.
    return route != null && route.isCurrent;
  }

  @override
  void initState() {
    super.initState();
    _loadMatches();
    // Actualizamos la UI cada segundo para que el tiempo transcurrido
    // de los partidos en juego se vea en tiempo real.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isThisRouteVisible()) return;
      setState(() {});
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
    _liveGoalsScored.clear();
    _liveGoalsConceded.clear();
    _liveScoresScheduleKey = null;
  }

  void _scheduleLiveScoresFetch(List<Match> matches) {
    final key = matches.map((m) => m.id).join(',');
    if (_liveScoresScheduleKey == key) return;
    _liveScoresScheduleKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureLiveScoresLoaded(matches);
    });
  }

  String _statusText(MatchStatus status) {
    switch (status) {
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
        final route = ModalRoute.of(context);
        if (route == null || !route.isCurrent) return;
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

              _scheduleLiveScoresFetch(matches);

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final scheme = Theme.of(context).colorScheme;
                  final dateText =
                      '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} · ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';
                  final liveScored = _liveGoalsScored[match.id];
                  final liveConceded = _liveGoalsConceded[match.id];
                  final us = liveScored ?? match.goalsScored;
                  final them = liveConceded ?? match.goalsConceded;
                  final elapsed = _elapsedText(match);
                  final statusText = _statusText(match.status);
                  final inPlay = match.status == MatchStatus.firstHalf ||
                      match.status == MatchStatus.secondHalf;
                  final showTimer = inPlay && elapsed != '-';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          if (match.status == MatchStatus.notStarted) {
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
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateText,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: scheme
                                                    .surfaceContainerHigh,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                match.isHome
                                                    ? 'Local'
                                                    : 'Visitante',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: scheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  _MatchStatusChip(
                                    status: match.status,
                                    label: statusText,
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: scheme.outline,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.team.name,
                                        textAlign: TextAlign.end,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '$us',
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              color: scheme.primary,
                                              height: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Text(
                                              '—',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: scheme.outline,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$them',
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              color: scheme.onSurface,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        match.opponent,
                                        textAlign: TextAlign.start,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (showTimer) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: scheme.tertiary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tiempo: $elapsed',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.tertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (match.status ==
                                  MatchStatus.notStarted) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Pulsa para alinear y empezar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else if (match.status ==
                                  MatchStatus.halfTime) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Pulsa para gestionar o reanudar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else if (match.status ==
                                  MatchStatus.finished) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Pulsa para ver estadísticas',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
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

class _MatchStatusChip extends StatelessWidget {
  const _MatchStatusChip({
    required this.status,
    required this.label,
  });

  final MatchStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final IconData icon;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case MatchStatus.notStarted:
        icon = Icons.schedule_outlined;
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
      case MatchStatus.firstHalf:
      case MatchStatus.secondHalf:
        icon = Icons.sports_soccer;
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
      case MatchStatus.halfTime:
        icon = Icons.pause_circle_outline;
        bg = scheme.secondaryContainer;
        fg = scheme.onSecondaryContainer;
      case MatchStatus.finished:
        icon = Icons.flag_outlined;
        bg = scheme.surfaceContainer;
        fg = scheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
