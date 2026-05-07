import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/match/get_match_lineups_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_matches_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_events_by_match_use_case.dart';
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

/// Devuelve el texto localizado del estado del partido en lista.
/// Lo hace usando un switch sobre [MatchStatus].
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

/// Formatea fecha y hora para mostrar en la tarjeta.
/// Lo hace con padLeft para dia, mes, hora y minuto.
String _formatMatchDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month · $hour:$minute';
}

/// Requiere [TeamContextCubit] en el arbol.
/// Lista de partidos con acceso a gestion y estadisticas.
class MatchListPage extends StatefulWidget {
  /// Crea la pagina de lista de partidos.
  const MatchListPage({super.key});

  /// Crea el estado asociado.
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

  /// Indica si esta ruta es la visible actualmente.
  /// Lo hace consultando [ModalRoute.isCurrent].
  bool _isThisRouteVisible() {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    // Si no hay ruta o hay otra encima (p. ej. gestor de partido), no
    // reconstruimos: evita asserts de semántica/layout en la ruta inferior.
    return route != null && route.isCurrent;
  }

  /// Inicializa observer, carga inicial y timer de refresco.
  /// Lo hace registrando el observer y programando el Timer.periodic.
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

  /// Reacciona al ciclo de vida para refrescar al reanudar.
  /// Lo hace llamando a setState cuando vuelve a foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        mounted &&
        _isThisRouteVisible()) {
      setState(() {});
    }
  }

  /// Libera recursos del observer y del timer.
  /// Lo hace removiendo el observer y cancelando el timer.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  /// Lanza la carga de partidos y reinicia marcadores en vivo.
  /// Lo hace leyendo el equipo actual y reseteando caches locales.
  void _loadMatches() {
    final teamId = context.read<TeamContextCubit>().state.id;
    _matchesFuture = context.read<GetMatchesByTeamUseCase>().call(teamId);
    _liveGoalsScored.clear();
    _liveGoalsConceded.clear();
    _liveScoresScheduleKey = null;
  }

  /// Maneja el pull-to-refresh y espera al future.
  /// Lo hace disparando _loadMatches y aguardando su resultado.
  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(_loadMatches);
    try {
      await _matchesFuture;
    } catch (_) {
      // El FutureBuilder mostrará el error devuelto por el caso de uso.
    }
  }

  /// Programa una lectura de marcadores en vivo para la lista actual.
  /// Lo hace con una clave de ids y un post-frame callback.
  void _scheduleLiveScoresFetch(List<Match> matches) {
    final key = matches.map((m) => m.id).join(',');
    if (_liveScoresScheduleKey == key) return;
    _liveScoresScheduleKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureLiveScoresLoaded(matches);
    });
  }

  /// Calcula el tiempo transcurrido de un partido en juego.
  /// Lo hace con el diff entre ahora y la fecha del partido.
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

  /// Consulta Supabase para calcular goles en vivo por partido.
  /// Lo hace leyendo eventos y acumulando marcadores locales.
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
          final typeString = canonicalMatchEventTypeKey(raw);

          if (typeString == 'scoregoal') {
            scored++;
          } else if (typeString == 'concedegoal' || typeString == 'owngoal') {
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

  /// Abre gestion o estadisticas segun el estado del partido.
  /// Lo hace navegando a la pantalla correspondiente.
  Future<void> _openMatch(Match match, Team team) async {
    if (match.status == MatchStatus.finished) {
      await _openMatchStats(match);
    } else {
      await _openMatchManager(match, team);
    }
  }

  /// Abre el gestor de partido y recarga al volver.
  /// Lo hace usando Navigator.push y luego _loadMatches.
  Future<void> _openMatchManager(Match match, Team team) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<TeamContextCubit>()),
            BlocProvider(create: (_) => LoadingCubit()),
          ],
          child: MatchManagerPage(team: team, match: match),
        ),
      ),
    );

    if (mounted) {
      setState(_loadMatches);
    }
  }

  /// Abre la pantalla de estadisticas con su cubit.
  /// Lo hace creando el cubit con casos de uso y navegando.
  Future<void> _openMatchStats(Match match) async {
    final getPlayersByTeamUseCase = context.read<GetPlayersByTeamUseCase>();
    final getMatchEventsByMatchUseCase = context
        .read<GetMatchEventsByMatchUseCase>();
    final getMatchLineupsByMatchUseCase = context
        .read<GetMatchLineupsByMatchUseCase>();
    final getLatestFormationNoteByMatchUseCase = context
        .read<GetLatestFormationNoteByMatchUseCase>();
    final loadErrorMessage = AppLocalizations.of(context)!.matchStatsLoadError;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<TeamContextCubit>()),
            BlocProvider(
              create: (ctx) => MatchStatsCubit(
                match: match,
                getPlayersByTeamUseCase: getPlayersByTeamUseCase,
                getMatchEventsByMatchUseCase: getMatchEventsByMatchUseCase,
                getMatchLineupsByMatchUseCase: getMatchLineupsByMatchUseCase,
                getLatestFormationNoteByMatchUseCase:
                    getLatestFormationNoteByMatchUseCase,
                loadErrorMessage: loadErrorMessage,
              )..load(),
            ),
          ],
          child: MatchStatsPage(match: match),
        ),
      ),
    );
  }

  /// Envuelve el contenido en un Card centrado y scrolleable.
  /// Lo hace con SingleChildScrollView y ConstrainedBox.
  Widget _buildScrollableCard({
    required BoxConstraints constraints,
    required Widget child,
    double maxWidth = 400,
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Card(child: child),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el estado de carga con indicador y texto.
  /// Lo hace reusando _buildScrollableCard.
  Widget _buildLoadingState(
    BoxConstraints constraints,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    return _buildScrollableCard(
      constraints: constraints,
      maxWidth: 320,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: scheme.primary),
            const SizedBox(height: 20),
            Text(
              l10n.matchListLoading,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el estado de error con icono y mensaje.
  /// Lo hace reusando _buildScrollableCard.
  Widget _buildErrorState(
    BoxConstraints constraints,
    ColorScheme scheme,
    String message, {
    IconData icon = Icons.error_outline,
  }) {
    return _buildScrollableCard(
      constraints: constraints,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, color: scheme.error, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el estado vacio con icono y copy.
  /// Lo hace reusando _buildScrollableCard.
  Widget _buildEmptyState(
    BoxConstraints constraints,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    return _buildScrollableCard(
      constraints: constraints,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sports_soccer, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.matchListEmptyStateTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.matchListEmptyStateBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de un partido en la lista.
  /// Lo hace componiendo fecha, estado y marcador.
  Widget _buildMatchCard(
    Match match,
    Team team,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    final dateText = _formatMatchDateTime(match.date);
    final liveScored = _liveGoalsScored[match.id];
    final liveConceded = _liveGoalsConceded[match.id];
    final us = liveScored ?? match.goalsScored;
    final them = liveConceded ?? match.goalsConceded;
    final elapsed = _elapsedText(match);
    final statusText = _matchListStatusLabel(l10n, match.status);
    final inPlay =
        match.status == MatchStatus.firstHalf ||
        match.status == MatchStatus.secondHalf;
    final showTimer = inPlay && elapsed != '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openMatch(match, team),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                borderRadius: BorderRadius.circular(6),
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
                    _MatchStatusChip(status: match.status, label: statusText),
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
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
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
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
                ] else if (match.status == MatchStatus.notStarted) ...[
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
                ] else if (match.status == MatchStatus.halfTime) ...[
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
                ] else if (match.status == MatchStatus.finished) ...[
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
  }

  /// Construye la pagina con AppBar, refresco y listado.
  /// Lo hace con FutureBuilder y estados dedicados.
  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamContextCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    return TeamBrandedScope(
      team: team,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.screenMatches),
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
                        return _buildLoadingState(constraints, l10n, scheme);
                      },
                    );
                  }

                  if (!snapshot.hasData) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildErrorState(
                          constraints,
                          scheme,
                          l10n.matchListLoadError,
                        );
                      },
                    );
                  }

                  final either = snapshot.data!;
                  return either.fold(
                    (failure) => LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildErrorState(
                          constraints,
                          scheme,
                          failure.message,
                          icon: Icons.cloud_off_outlined,
                        );
                      },
                    ),
                    (List<Match> matches) {
                      if (matches.isEmpty) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return _buildEmptyState(constraints, l10n, scheme);
                          },
                        );
                      }

                      matches.sort(
                        (Match a, Match b) => b.date.compareTo(a.date),
                      );

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
                          return _buildMatchCard(match, team, l10n, scheme);
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

/// Chip con icono y colores segun el estado del partido.
/// Lo hace asignando estilo en base a [MatchStatus].
class _MatchStatusChip extends StatelessWidget {
  const _MatchStatusChip({required this.status, required this.label});

  final MatchStatus status;
  final String label;

  /// Construye el chip resolviendo icono y colores.
  /// Lo hace con un switch y un Container decorado.
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
