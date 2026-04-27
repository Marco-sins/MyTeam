import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/utils/match_category_duration.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/usecase/match/get_match_lineups_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_first_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_event_aggregates_from_events_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_events_by_match_use_case.dart';
import 'package:football_manager/data/team_scoring_config_storage.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/pages/match_stats_page.dart';
import 'package:football_manager/presentation/match/pages/match_manager_page.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/presentation/team/widgets/team_area_background.dart';
import 'package:football_manager/presentation/team/team_session_routes.dart';
import 'package:football_manager/presentation/team/widgets/team_bottom_bar.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

String _matchListStatusLabel(AppLocalizations l10n, MatchStatus status) {
  switch (status) {
    case MatchStatus.notStarted:
      return l10n.matchStatusPending;
    case MatchStatus.firstHalf:
      return l10n.matchStatusFirstHalf;
    case MatchStatus.halfTime:
      return l10n.matchStatusHalfTime;
    case MatchStatus.secondHalf:
      return l10n.matchStatusSecondHalf;
    case MatchStatus.finished:
      return l10n.matchStatusFinished;
  }
}

/// Requiere [TeamContextCubit] en el árbol.
class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _loadMatches();
    // Actualizamos la UI cada segundo para que el tiempo transcurrido
    // de los partidos en juego se vea en tiempo real.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isThisRouteVisible()) return;
      setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted && _isThisRouteVisible()) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _loadMatches() {
    final teamId = context.read<TeamContextCubit>().state.id;
    _matchesFuture = context.read<GetMatchesByTeamUseCase>().call(
      teamId,
    );
    _liveGoalsScored.clear();
    _liveGoalsConceded.clear();
    _liveScoresScheduleKey = null;
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(_loadMatches);
    try {
      await _matchesFuture;
    } catch (_) {
      // El FutureBuilder mostrará el error devuelto por el caso de uso.
    }
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

  String _elapsedText(Match match, String teamCategory) {
    // Solo mostramos el timer en 1ª y 2ª parte; en descanso no.
    if (match.status != MatchStatus.firstHalf &&
        match.status != MatchStatus.secondHalf) {
      return '-';
    }

    final now = DateTime.now();
    var diff = now.difference(match.date).inSeconds;
    if (diff < 0) return '0:00';
    if (match.status == MatchStatus.secondHalf) {
      // [Match.date] es el inicio de la 2ª parte: el reloj sigue desde el minuto
      // de fin de la 1ª (categoría: p. ej. 25' prebenjamines, 45' seniors).
      diff += matchHalfDurationMinutesForCategory(teamCategory) * 60;
    }

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
    final team = context.watch<TeamContextCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    return TeamBrandedScope(
      team: team,
      child: Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.screenMatches),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              TeamSessionRoutes.detailHomeReplacingStack(context),
              (route) => route.isFirst,
            );
          },
        ),
        actions: const [TeamQuickNavAppBarButton()],
      ),
      body: TeamAreaBackground(
        team: team,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder(
            future: _matchesFuture,
            builder: (context, snapshot) {
              final scheme = Theme.of(context).colorScheme;

              if (snapshot.connectionState == ConnectionState.waiting) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
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
                                        l10n.matchListLoading,
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
                );
              }

              if (!snapshot.hasData) {
                return LayoutBuilder(
                  builder: (context, constraints) {
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
                                  padding: const EdgeInsets.all(22),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: scheme.error,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          l10n.matchListLoadError,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
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
                );
              }

              final either = snapshot.data!;
              return either.fold(
                (failure) => LayoutBuilder(
                  builder: (context, constraints) {
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
                                  padding: const EdgeInsets.all(22),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_off_outlined,
                                        color: scheme.error,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          failure.message,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
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
                (List<Match> matches) {
                  if (matches.isEmpty) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: scheme
                                                  .primaryContainer
                                                  .withValues(alpha: 0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.sports_soccer,
                                              size: 40,
                                              color: scheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            l10n.matchListEmptyStateTitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.matchListEmptyStateBody,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  height: 1.4,
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
                    );
                  }

                  matches.sort((Match a, Match b) => b.date.compareTo(a.date));

                  _scheduleLiveScoresFetch(matches);

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: 88),
                    itemCount: matches.length + 1,
                    itemBuilder: (context, index) {
                      final scheme = Theme.of(context).colorScheme;
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 22,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.matchListCalendarTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                team.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      final match = matches[index - 1];
                  final dateText =
                      '${match.date.day.toString().padLeft(2, '0')}/${match.date.month.toString().padLeft(2, '0')} · ${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';
                  final liveScored = _liveGoalsScored[match.id];
                  final liveConceded = _liveGoalsConceded[match.id];
                  final us = liveScored ?? match.goalsScored;
                  final them = liveConceded ?? match.goalsConceded;
                  final elapsed = _elapsedText(match, team.category);
                  final statusText = _matchListStatusLabel(l10n, match.status);
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
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(
                                      value: context.read<TeamContextCubit>(),
                                    ),
                                    BlocProvider(
                                      create: (_) => LoadingCubit(),
                                    ),
                                  ],
                                  child: MatchManagerPage(
                                    team: team,
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
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(
                                      value: context.read<TeamContextCubit>(),
                                    ),
                                    BlocProvider(
                                      create: (_) => LoadingCubit(),
                                    ),
                                  ],
                                  child: MatchManagerPage(
                                    team: team,
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
                            final getMatchEventsByMatchUseCase = context
                                .read<GetMatchEventsByMatchUseCase>();
                            final getMatchLineupsByMatchUseCase = context
                                .read<GetMatchLineupsByMatchUseCase>();
                            final getFirstFormationNoteByMatchUseCase = context
                                .read<GetFirstFormationNoteByMatchUseCase>();
                            final getLatestFormationNoteByMatchUseCase = context
                                .read<GetLatestFormationNoteByMatchUseCase>();
                            final getMatchEventAggregatesFromEventsUseCase = context
                                .read<GetMatchEventAggregatesFromEventsUseCase>();
                            final teamScoringConfigStorage = context
                                .read<TeamScoringConfigStorage>();
                            final loadErrorMessage =
                                AppLocalizations.of(context)!.matchStatsLoadError;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (ctx) => MatchStatsCubit(
                                    match: match,
                                    getPlayersByTeamUseCase:
                                        getPlayersByTeamUseCase,
                                    getMatchEventsByMatchUseCase:
                                        getMatchEventsByMatchUseCase,
                                    getMatchLineupsByMatchUseCase:
                                        getMatchLineupsByMatchUseCase,
                                    getFirstFormationNoteByMatchUseCase:
                                        getFirstFormationNoteByMatchUseCase,
                                    getLatestFormationNoteByMatchUseCase:
                                        getLatestFormationNoteByMatchUseCase,
                                    getMatchEventAggregatesFromEventsUseCase:
                                        getMatchEventAggregatesFromEventsUseCase,
                                    teamScoringConfigStorage:
                                        teamScoringConfigStorage,
                                    loadErrorMessage: loadErrorMessage,
                                  )..load(),
                                  child: MatchStatsPage(
                                    match: match,
                                    ourTeamName: context
                                        .read<TeamContextCubit>()
                                        .state
                                        .name,
                                    teamColorHex: context
                                        .read<TeamContextCubit>()
                                        .state
                                        .color,
                                  ),
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
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: scheme.surfaceContainerHigh,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              match.isHome
                                                  ? l10n.matchVenueHome
                                                  : l10n.matchVenueAway,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
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
                                        team.name,
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
                                      l10n.matchListElapsedTime(elapsed),
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
                                  l10n.matchListHintLineupStart,
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
                                  l10n.matchListHintManageResume,
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
                                  l10n.matchListHintViewStats,
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
                },
              );
            },
          ),
        ),
        ),
      ),
      bottomNavigationBar: const TeamBottomBar(),
      ),
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
