import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/auth_user.dart' as tfg_auth;
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/entities/match_event_aggregates.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/core/utils/match_category_duration.dart';
import 'package:football_manager/domain/utils/match_minutes_utils.dart';
import 'package:football_manager/domain/repositories/i_match_spectator_realtime.dart';
import 'package:football_manager/domain/entities/match_live_timeline_row.dart';
import 'package:football_manager/domain/services/match_live_timeline_filter.dart';
import 'package:football_manager/domain/usecase/match/apply_match_half_time_status_use_case.dart';
import 'package:football_manager/domain/usecase/match/apply_match_lineup_starters_use_case.dart';
import 'package:football_manager/domain/usecase/match/apply_match_second_half_started_use_case.dart';
import 'package:football_manager/domain/usecase/match/fetch_convoked_player_ids_for_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/fetch_match_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_match_by_id_use_case.dart';
import 'package:football_manager/domain/usecase/match/finish_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/lock_initial_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/persist_match_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/start_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_match_lineups_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_first_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_formation_note_by_match_use_case.dart';
import 'package:football_manager/data/team_scoring_config_storage.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_event_aggregates_from_events_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_match_event_by_db_type_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_events_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_live_timeline_maps_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_sent_off_player_ids_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_player_card_summary_for_match_player_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_player_rating_event_rows_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/save_match_event_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/delete_match_event_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/match/utils/match_foul_icon.dart'
    show
        isMatchFoulCanonicalKey,
        kMatchFoulListAvatarBackground,
        kMatchFoulListAvatarForeground,
        MatchWhistleIcon;
import 'package:football_manager/presentation/match/utils/match_player_discipline_highlight.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_convocation_table.dart';
import 'package:football_manager/presentation/match/widgets/match_live_stats_panel.dart';
import 'package:football_manager/presentation/match/widgets/match_field_with_formation.dart';
import 'package:football_manager/presentation/match/widgets/match_player_action_modal.dart';
import 'package:football_manager/presentation/match/utils/team_scoring_line_match_save.dart';
import 'package:football_manager/presentation/match/pages/match_stats_page.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/core/theme/app_responsive.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

enum _MatchPhase { notStarted, firstHalf, halfTime, secondHalf }

class _SavedLineupState {
  final String formationKey;
  final List<int?> playerIds;

  const _SavedLineupState({
    required this.formationKey,
    required this.playerIds,
  });
}

class MatchManagerPage extends StatefulWidget {
  final Team team;
  final Match match;

  const MatchManagerPage({super.key, required this.team, required this.match});

  @override
  State<MatchManagerPage> createState() => _MatchManagerPageState();
}

class _MatchManagerPageState extends State<MatchManagerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static final Map<int, _SavedLineupState> _savedLineups = {};
  late Match _match;
  final List<Player> _convokedPlayers = [];
  bool _loadingPlayers = true;
  String? _loadError;

  // Media en tiempo real por jugador (0-10, base 5).
  Map<int, double> _playerRatings = {};

  // Jugadores expulsados (roja o doble amarilla).
  final Set<int> _sentOffPlayerIds = {};

  /// Tiros a puerta: eventos `shot` / `rivalShot`, más goles (`scoreGoal` → nuestro, `concedeGoal`/`ownGoal` → rival).
  int _shotsOur = 0;
  int _shotsRival = 0;

  /// Faltas propias (eventos `falta` por jugador) y del rival (`rivalFoul` manual).
  int _foulsOur = 0;
  int _foulsRival = 0;

  /// Córners (eventos `corner` / `rivalCorner`, manuales).
  int _cornersOur = 0;
  int _cornersRival = 0;

  /// Fueras de juego (eventos `offside` / `rivalOffside`, manuales).
  int _offsidesOur = 0;
  int _offsidesRival = 0;

  /// Tarjetas propias (`yellowCard` / `redCard` por jugador) y rival (manual).
  int _yellowOur = 0;
  int _yellowRival = 0;
  int _redOur = 0;
  int _redRival = 0;

  /// Cronología: 2ª arriba / 1ª abajo; en cada parte menos minuto abajo y más arriba.
  List<Map<String, dynamic>> _liveEvents = [];

  // Formaciones disponibles (solo líneas de jugadores de campo: defensa → delantero).
  // El contenido real depende de la categoría del equipo (fútbol 7 vs fútbol 11).
  late Map<String, List<int>> _formationOptions;

  // Incluye portero (1) + líneas de jugadores de campo
  late List<int> _formationLines;
  late String _selectedFormation;

  late List<Player?> _positionPlayers;
  Player? _selectedPlayer;
  List<int?>? _pendingPositionPlayerIds;

  Timer? _timer;
  /// Ancla en tiempo real del inicio del tramo actual (1ª o 2ª parte). [Match.date]
  /// en BD coincide: 1ª al arrancar el partido; 2ª al reanudar (el remoto la actualiza).
  DateTime? _activeSegmentStartedAt;
  /// Cuando el reloj no debe avanzar (descanso, diálogo de fin, etc.).
  int? _clockFrozenSegmentSeconds;
  _MatchPhase _phase = _MatchPhase.notStarted;
  bool _isTimerRunning = false;

  /// Segundos transcurridos en la parte actual (o congelados en descanso / fin).
  int get _elapsedSeconds {
    if (_clockFrozenSegmentSeconds != null) {
      return _clockFrozenSegmentSeconds!.clamp(0, 1 << 20);
    }
    if (_phase == _MatchPhase.halfTime) {
      return 0;
    }
    final start = _activeSegmentStartedAt;
    if (start == null) return 0;
    return (DateTime.now().difference(start).inSeconds).clamp(0, 1 << 20);
  }

  IMatchSpectatorRealtime? _spectatorRealtime;
  Timer? _spectatorRealtimeDebounce;

  /// Solo actualiza el reloj; evita [setState] a nivel de página cada segundo
  /// (reconstruía campo, convocatoria, cronología, etc.).
  final ValueNotifier<int> _clockTick = ValueNotifier<int>(0);

  late AnimationController _lastEventBlinkController;

  bool get _isExternal {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return false;
    return authState.user.teamRoles[widget.team.id] == UserRole.external;
  }

  /// Minutos disputados en la convocatoria: solo admins / superadmins.
  bool get _canSeeConvokedMinutesPlayed {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return false;
    final role = authState.user.teamRoles[widget.team.id];
    return role?.hasAdminPrivileges ?? false;
  }

  Map<int, int> _computeMinutesPlayedForConvoked() {
    final events = _liveEvents
        .map(
          (m) => MatchEvent.fromSupabaseMap(Map<String, dynamic>.from(m)),
        )
        .toList();

    final int? endOverride = _match.status == MatchStatus.finished
        ? null
        : (_match.status == MatchStatus.notStarted
            ? 0
            : _currentMatchMinute());

    // Titularidad: viene de [match_lineup] (is_start). No de [widget.match] —
    // al hacer merge con getMatchById el array lineups de la fila [matches] suele ir vacío.
    final starterById = <int, bool>{};
    for (final l in _match.lineups) {
      starterById[l.playerId] = l.isStarting;
    }

    final map = <int, int>{};
    for (final p in _convokedPlayers) {
      final isStarter = starterById[p.id] ??
          // Reserva: aún no cargó lineups pero el jugador está claramente de titular en el campo
          (starterById.isEmpty && _onFieldInCurrentLineup(p.id));
      map[p.id] = minutesPlayedForPlayer(
        events: events,
        playerId: p.id,
        isStarter: isStarter,
        overrideMatchEndMinute: endOverride,
      );
    }
    return map;
  }

  bool _onFieldInCurrentLineup(int playerId) {
    for (final player in _positionPlayers) {
      if (player?.id == playerId) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _match = widget.match;
    _initializeFormationOptions();
    final saved = _savedLineups[_match.id];
    if (saved != null && _formationOptions.containsKey(saved.formationKey)) {
      _selectedFormation = saved.formationKey;
      _pendingPositionPlayerIds = saved.playerIds;
    } else {
      // Primera formación disponible según categoría
      _selectedFormation = _formationOptions.keys.first;
      _pendingPositionPlayerIds = null;
    }

    final outfieldLines = _formationOptions[_selectedFormation]!;
    _formationLines = [1, ...outfieldLines];

    final totalPositions = _formationLines.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    _positionPlayers = List<Player?>.filled(totalPositions, null);
    // Evita condiciones de carrera: la formación desde BD debe aplicarse antes
    // de restaurar convocatoria y posiciones (varios setState en paralelo
    // disparaban asserts de layout/semántica y podían congelar la UI).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapMatchInitialData();
    });
    // Si el partido ya está en juego al entrar, arrancamos el cronómetro
    // en la fase correspondiente.
    if (_match.status == MatchStatus.firstHalf) {
      _phase = _MatchPhase.firstHalf;
      _initializeTimer();
    } else if (_match.status == MatchStatus.halfTime) {
      _phase = _MatchPhase.halfTime;
    } else if (_match.status == MatchStatus.secondHalf) {
      _phase = _MatchPhase.secondHalf;
      _initializeTimer();
    } else {
      _phase = _MatchPhase.notStarted;
    }

    _lastEventBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  bool get _showLiveLastEventHighlight {
    if (_liveEvents.isEmpty) return false;
    switch (_match.status) {
      case MatchStatus.firstHalf:
      case MatchStatus.halfTime:
      case MatchStatus.secondHalf:
        return true;
      case MatchStatus.notStarted:
      case MatchStatus.finished:
        return false;
    }
  }

  Widget _buildLiveLastEventBlinkBanner(
    ThemeData theme,
    ColorScheme scheme,
    bool isExternal,
    AppLocalizations l10n,
  ) {
    final row = _liveEvents.first;
    final baseStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w600,
    );
    final minute = resolveMatchEventMinute(
      Map<String, dynamic>.from(row),
    );
    final half = _eventMatchHalf(row, _resolvedSecondHalfStart());
    final minuteLine = _liveEventMinuteLabel(l10n, row, minute, half);
    const radius = 14.0;

    return AnimatedBuilder(
      animation: _lastEventBlinkController,
      builder: (context, child) {
        final raw = _lastEventBlinkController.value;
        final t = Curves.easeInOutCubic.transform(raw);
        final breathe = 0.5 - 0.5 * (t - 0.5).abs() * 2;
        final pulse = 0.35 + 0.65 * t;
        final scale = 0.988 + 0.012 * t;
        final glow = 0.12 + 0.38 * pulse;
        final blur = 10.0 + 18.0 * pulse;
        final yOff = 2.0 + 5.0 * pulse;
        final spread = -0.5 + 2.5 * pulse;
        final fillAlpha = 0.38 + 0.22 * t;
        final accentGlow = scheme.secondary.withValues(alpha: 0.06 + 0.14 * breathe);

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius + 2),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: glow),
                  blurRadius: blur,
                  spreadRadius: spread,
                  offset: Offset(0, yOff),
                ),
                BoxShadow(
                  color: accentGlow,
                  blurRadius: 22 + 12 * breathe,
                  spreadRadius: 0,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: scheme.primaryContainer.withValues(alpha: fillAlpha),
                border: Border.all(
                  width: 1.15 + 1.1 * pulse,
                  color: Color.lerp(
                    scheme.outline.withValues(alpha: 0.45),
                    scheme.primary.withValues(alpha: 0.82),
                    pulse,
                  )!,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: isExternal ? null : () => _onLiveEventTapped(row),
                  borderRadius: BorderRadius.circular(radius),
                  splashColor: scheme.primary.withValues(alpha: 0.12),
                  highlightColor: scheme.primary.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.scale(
                          scale: 1.0 + 0.07 * pulse,
                          child: () {
                            final evK = _canonicalEventTypeKey(row['type']);
                            if (isMatchFoulCanonicalKey(evK)) {
                              return MatchWhistleIcon(
                                size: 22,
                                color: kMatchFoulListAvatarForeground,
                              );
                            }
                            return Icon(
                              _iconForLiveEventKey(evK),
                              color: scheme.primary,
                              size: 22,
                            );
                          }(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.matchLastEvent,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onPrimaryContainer.withValues(
                                    alpha: 0.82 + 0.18 * t,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.35,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  style: baseStyle,
                                  children: [
                                    TextSpan(
                                      text: '$minuteLine · ',
                                      style: baseStyle.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    ..._liveEventDescriptionSpans(
                                      l10n,
                                      row,
                                      baseStyle,
                                    ),
                                  ],
                                ),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastEventBlinkController.dispose();
    _clockTick.dispose();
    _timer?.cancel();
    _spectatorRealtimeDebounce?.cancel();
    final rt = _spectatorRealtime;
    _spectatorRealtime = null;
    if (rt != null) {
      unawaited(rt.unsubscribe());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      if (_phase == _MatchPhase.firstHalf || _phase == _MatchPhase.secondHalf) {
        if (_isTimerRunning) _clockTick.value++;
      }
    }
  }

  void _startTimer() {
    _isTimerRunning = true;
    _timer?.cancel();
    // Reloj: actualiza [ValueListenableBuilder] del reloj, no toda la pantalla.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isTimerRunning || !mounted) return;
      _clockTick.value++;
    });
  }

  void _syncLocalPhaseWithMatch() {
    switch (_match.status) {
      case MatchStatus.notStarted:
        _phase = _MatchPhase.notStarted;
        break;
      case MatchStatus.firstHalf:
        _phase = _MatchPhase.firstHalf;
        break;
      case MatchStatus.halfTime:
        _phase = _MatchPhase.halfTime;
        break;
      case MatchStatus.secondHalf:
        _phase = _MatchPhase.secondHalf;
        break;
      case MatchStatus.finished:
        break;
    }
  }

  Future<void> _mergeMatchFromServer() async {
    final uc = context.read<GetMatchByIdUseCase>();
    final result = await uc(_match.id);
    await result.fold<Future<void>>(
      (_) async {},
      (m) async {
        if (!mounted) return;
        final results = await Future.wait<dynamic>([
          _queryEventAggregatesFromEvents(),
          _queryLiveEventsFiltered(),
        ]);
        if (!mounted) return;
        final MatchEventAggregates? agg = results[0] as MatchEventAggregates?;
        final List<Map<String, dynamic>>? live =
            results[1] as List<Map<String, dynamic>>?;
        setState(() {
          _match = m;
          _syncLocalPhaseWithMatch();
          if (agg != null) {
            _applyEventAggregates(agg);
          }
          if (live != null) {
            _liveEvents = live;
          }
          switch (_match.status) {
            case MatchStatus.firstHalf:
            case MatchStatus.secondHalf:
              _activeSegmentStartedAt = _match.date;
              _clockFrozenSegmentSeconds = null;
              if (!_isTimerRunning) {
                _startTimer();
              }
              break;
            case MatchStatus.halfTime:
              _isTimerRunning = false;
              _timer?.cancel();
              _activeSegmentStartedAt = null;
              _clockFrozenSegmentSeconds = null;
              break;
            case MatchStatus.notStarted:
            case MatchStatus.finished:
              _isTimerRunning = false;
              _timer?.cancel();
              _activeSegmentStartedAt = null;
              _clockFrozenSegmentSeconds = null;
              break;
          }
          if (_match.status == MatchStatus.halfTime) {
            _tryRestoreHalfTimeClockFromEvents();
          }
        });
        if (mounted) await _loadMatchLineupsForMatchState();
      },
    );
  }

  /// Rellena [_match].lineups desde [match_lineup] (is_start, minutos, etc.):
  /// necesario para minutos de titulares y no depender de un join inexistente en getMatchById.
  Future<void> _loadMatchLineupsForMatchState() async {
    final lineupsUc = context.read<GetMatchLineupsByMatchUseCase>();
    final res = await lineupsUc(_match.id);
    if (!mounted) return;
    res.fold(
      (failure) {
        debugPrint('No se pudo cargar alineación del partido: ${failure.message}');
      },
      (lineups) {
        if (!mounted) return;
        setState(() {
          _match = Match(
            id: _match.id,
            teamId: _match.teamId,
            opponent: _match.opponent,
            goalsScored: _match.goalsScored,
            goalsConceded: _match.goalsConceded,
            date: _match.date,
            hour: _match.hour,
            status: _match.status,
            lineups: lineups,
            isHome: _match.isHome,
          );
        });
      },
    );
  }

  void _tryRestoreHalfTimeClockFromEvents() {
    if (_match.status != MatchStatus.halfTime) return;
    if (_clockFrozenSegmentSeconds != null) return;
    final firstStart = _match.date;
    DateTime? bestEnd;
    for (final m in _liveEvents) {
      final note = m['note'] as String?;
      if (note != 'Descanso') continue;
      final row = MatchLiveTimelineRow.fromPostgresMap(
        Map<String, dynamic>.from(m),
      );
      final end = row.createdAt;
      if (bestEnd == null || end.isAfter(bestEnd)) {
        bestEnd = end;
      }
    }
    if (bestEnd != null) {
      final sec = bestEnd.difference(firstStart).inSeconds;
      if (sec >= 0) {
        _clockFrozenSegmentSeconds = sec.clamp(0, 1 << 20);
      }
    }
  }

  Future<void> _bootstrapMatchInitialData() async {
    if (!mounted) return;
    await _mergeMatchFromServer();
    if (!mounted) return;
    await _loadLastFormationFromEvents();
    if (!mounted) return;
    await _loadConvocationPlayers();
    if (!mounted) return;
    _subscribeSpectatorRealtime();
  }

  /// Supabase Realtime: cualquier cambio en [match_events], [match_lineup] o [matches]
  /// (goles, estadísticas, alineación, estado) dispara un refresco en **todos** los dispositivos.
  void _subscribeSpectatorRealtime() {
    if (_spectatorRealtime != null) return;
    if (_match.status == MatchStatus.finished) return;

    final mid = _match.id;
    void onRemoteChange() {
      if (!mounted) return;
      _scheduleSpectatorRealtimeRefresh();
    }

    final port = context.read<IMatchSpectatorRealtime>();
    _spectatorRealtime = port;
    // Notificaciones locales: [MatchEventAppNotificationCoordinator] (toda la app).
    port.subscribeToMatch(mid, onRemoteChange);
  }

  void _scheduleSpectatorRealtimeRefresh() {
    _spectatorRealtimeDebounce?.cancel();
    _spectatorRealtimeDebounce = Timer(const Duration(milliseconds: 400), () {
      _spectatorRealtimeDebounce = null;
      if (!mounted) return;
      unawaited(_onRefreshMatchScreen());
    });
  }

  bool _isSmallSideCategory() {
    final cat = widget.team.category.toLowerCase();

    if (cat.contains('prebenjamin') || cat.contains('prebenjamín')) {
      return true;
    }
    if (cat.contains('benjamin') || cat.contains('benjamín')) {
      return true;
    }
    if (cat.contains('alevin') || cat.contains('alevín')) {
      return true;
    }

    return false;
  }

  void _initializeFormationOptions() {
    if (_isSmallSideCategory()) {
      // Categorías pequeñas (fútbol 7).
      _formationOptions = {
        '3-2-1': [3, 2, 1],
        '3-3': [3, 3],
        '2-3-1': [2, 3, 1],
        '2-2-2': [2, 2, 2],
      };
    } else {
      // Infantil, cadete, juvenil, senior (fútbol 11) con nuevas formaciones.
      _formationOptions = {
        '4-4-2': [4, 4, 2],
        '4-3-3': [4, 3, 3],
        '4-2-3-1': [4, 2, 3, 1],
        '3-5-2': [3, 5, 2],
        '4-1-4-1': [4, 1, 4, 1],
        '3-4-3': [3, 4, 3],
      };
    }
  }

  void _initializeTimer() {
    _activeSegmentStartedAt = _match.date;
    _clockFrozenSegmentSeconds = null;
    _startTimer();
  }

  bool get _allPositionsFilled =>
      _positionPlayers.isNotEmpty &&
      _positionPlayers.every((player) => player != null);

  int _currentPlayersOnField() {
    return _positionPlayers.where((p) => p != null).length;
  }

  int _maxPlayersOnField() {
    final totalPositions = _positionPlayers.length;
    final expelledCount = _sentOffPlayerIds.length;
    final maxAllowed = totalPositions - expelledCount;
    return maxAllowed < 0 ? 0 : maxAllowed;
  }

  /// Convocados en banquillo: no están en el campo. Incluye reservas y **expulsados**
  /// (misma franja; el estilo de tarjeta indica no jugables).
  List<Player> get _benchPlayers {
    final onField = <int>{};
    for (final p in _positionPlayers) {
      if (p != null) onField.add(p.id);
    }
    final out = <Player>[];
    for (final p in _convokedPlayers) {
      if (onField.contains(p.id)) continue;
      out.add(p);
    }
    int byDorsalThenSentOffLast(Player a, Player b) {
      final aOff = _sentOffPlayerIds.contains(a.id);
      final bOff = _sentOffPlayerIds.contains(b.id);
      if (aOff != bOff) {
        return aOff ? 1 : -1; // reservas antes que expulsados
      }
      final na = a.number ?? 9999;
      final nb = b.number ?? 9999;
      return na.compareTo(nb);
    }

    out.sort(byDorsalThenSentOffLast);
    return out;
  }

  void _saveCurrentLineup() {
    final playerIds = _positionPlayers.map((p) => p?.id).toList();
    _savedLineups[_match.id] = _SavedLineupState(
      formationKey: _selectedFormation,
      playerIds: playerIds,
    );
  }

  Future<void> _persistCurrentPositionsToMatchLineup() async {
    try {
      final Map<int, int> positionByPlayerId = {};
      for (int i = 0; i < _positionPlayers.length; i++) {
        final player = _positionPlayers[i];
        if (player != null) {
          positionByPlayerId[player.id] = i;
        }
      }

      final uc = context.read<PersistMatchLineupPositionsUseCase>();
      final res = await uc(
        matchId: _match.id,
        convokedPlayerIds: _convokedPlayers.map((p) => p.id).toList(),
        onFieldPositionByPlayerId: positionByPlayerId,
      );
      res.fold((f) => debugPrint(f.message), (_) {});
    } catch (e) {
      debugPrint('Error updating positions in match_lineup: $e');
    }
  }

  void _changeFormation(String newKey) {
    setState(() {
      _selectedFormation = newKey;
      final outfieldLines = _formationOptions[newKey]!;
      _formationLines = [1, ...outfieldLines];
      final totalPositions = _formationLines.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      final old = _positionPlayers;
      final resized = List<Player?>.filled(totalPositions, null);
      final copyCount = totalPositions < old.length
          ? totalPositions
          : old.length;
      for (int i = 0; i < copyCount; i++) {
        resized[i] = old[i];
      }
      _positionPlayers = resized;
      _selectedPlayer = null;
      _pendingPositionPlayerIds = null;
    });
    _saveFormationEvent();
  }

  Future<void> _showFormationPicker() async {
    if (_isExternal) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SimpleDialog(
          title: Text(l10n.matchFormation),
          children: [
            for (final key in _formationOptions.keys)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, key),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(key, style: const TextStyle(fontSize: 17)),
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (!mounted || choice == null) return;
    _changeFormation(choice);
  }

  void _restorePositionsIfSaved() {
    if (_pendingPositionPlayerIds == null) return;
    if (_pendingPositionPlayerIds!.length != _positionPlayers.length) {
      _pendingPositionPlayerIds = null;
      return;
    }

    final List<Player?> newPositions = List<Player?>.filled(
      _positionPlayers.length,
      null,
    );

    for (int i = 0; i < _pendingPositionPlayerIds!.length; i++) {
      final playerId = _pendingPositionPlayerIds![i];
      if (playerId == null) continue;
      final player = _convokedPlayers.firstWhere(
        (p) => p.id == playerId,
        orElse: () =>
            const Player(teamId: 0, firstName: ''), // placeholder no usado
      );
      if (player.id != 0) {
        newPositions[i] = player;
      }
    }

    setState(() {
      _positionPlayers = newPositions;
      _pendingPositionPlayerIds = null;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _firstHalfDurationMinutesForCategory() {
    return matchHalfDurationMinutesForCategory(widget.team.category);
  }

  /// Reloj principal (MM:SS): en 2ª parte continúa desde el final de la 1ª
  /// (p. ej. prebenjamines 25:00→50:00; seniors 45:00→90:00).
  int _displayClockMainTotalSeconds() {
    if (_phase == _MatchPhase.secondHalf) {
      return _firstHalfDurationMinutesForCategory() * 60 + _mainClockSeconds();
    }
    return _mainClockSeconds();
  }

  int _currentMatchMinute() {
    final baseMinutes = _elapsedSeconds ~/ 60;
    if (_phase == _MatchPhase.secondHalf) {
      // Sumamos la duración de la 1ª parte según categoría
      return baseMinutes + _firstHalfDurationMinutesForCategory();
    }
    return baseMinutes;
  }

  int _halfDurationSeconds() => _firstHalfDurationMinutesForCategory() * 60;

  /// Cronómetro: tiempo transcurrido de la parte (sube desde 0:00), topeado al reglamentario.
  int _mainClockSeconds() {
    final limit = _halfDurationSeconds();
    final value = _elapsedSeconds <= limit ? _elapsedSeconds : limit;
    return value < 0 ? 0 : value;
  }

  int _extraClockSeconds() {
    final limit = _halfDurationSeconds();
    if (_elapsedSeconds <= limit) return 0;
    return _elapsedSeconds - limit;
  }

  Future<void> _saveStatusChangeEvent(MatchStatus newStatus, int minute) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        return;
      }

      final saveMatchEventUseCase = context.read<SaveMatchEventUseCase>();

      String note;
      switch (newStatus) {
        case MatchStatus.firstHalf:
          note = 'Inicio 1ª parte';
          break;
        case MatchStatus.halfTime:
          note = 'Descanso';
          break;
        case MatchStatus.secondHalf:
          note = 'Inicio 2ª parte';
          break;
        case MatchStatus.finished:
          note = 'Final del partido';
          break;
        default:
          note = newStatus.toString().split('.').last;
      }

      final event = MatchEvent(
        id: 0,
        matchId: _match.id,
        playerId1: null,
        playerId2: null,
        minute: minute,
        type: MatchEventEnum.statusChange,
        note: note,
      );

      await saveMatchEventUseCase(event, authState.user, widget.team.id);
      if (mounted) await _loadLiveEvents();
    } catch (e) {
      debugPrint('Error saving status change event: $e');
    }
  }

  Future<MatchEventAggregates?> _queryEventAggregatesFromEvents() async {
    try {
      final uc = context.read<GetMatchEventAggregatesFromEventsUseCase>();
      final result = await uc(_match.id);
      return result.fold((_) => null, (a) => a);
    } catch (_) {
      return null;
    }
  }

  void _applyEventAggregates(MatchEventAggregates agg) {
    _match = Match(
      id: _match.id,
      teamId: _match.teamId,
      opponent: _match.opponent,
      goalsScored: agg.goalsScored,
      goalsConceded: agg.goalsConceded,
      date: _match.date,
      hour: _match.hour,
      status: _match.status,
      lineups: _match.lineups,
      isHome: _match.isHome,
    );
    _shotsOur = agg.shotsOur;
    _shotsRival = agg.shotsRival;
    _foulsOur = agg.foulsOur;
    _foulsRival = agg.foulsRival;
    _cornersOur = agg.cornersOur;
    _cornersRival = agg.cornersRival;
    _offsidesOur = agg.offsidesOur;
    _offsidesRival = agg.offsidesRival;
    _yellowOur = agg.yellowOur;
    _yellowRival = agg.yellowRival;
    _redOur = agg.redOur;
    _redRival = agg.redRival;
  }

  /// Un solo [setState] para agregados + cronología (evita parpadeos 0 y doble repintado).
  Future<void> _reloadScoreAndLiveEventsBatched() async {
    final agg = await _queryEventAggregatesFromEvents();
    final live = await _queryLiveEventsFiltered();
    if (!mounted) return;
    if (agg == null && live == null) return;
    setState(() {
      if (agg != null) {
        _applyEventAggregates(agg);
      }
      if (live != null) {
        _liveEvents = live;
      }
    });
  }

  Future<void> _saveManualCounterEvent({
    required MatchEventEnum type,
    required String note,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isExternal) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack(l10n.matchMustLoginRegisterGoals, error: true);
      return;
    }
    final saveMatchEventUseCase = context.read<SaveMatchEventUseCase>();
    final minute = _currentMatchMinute();
    final event = MatchEvent(
      id: 0,
      matchId: _match.id,
      playerId1: null,
      playerId2: null,
      minute: minute,
      type: type,
      note: note,
    );
    final result = await saveMatchEventUseCase(
      event,
      authState.user,
      widget.team.id,
    );
    await result.fold<Future<void>>(
      (failure) async {
        _showSnack(failure.message, error: true);
      },
      (_) async {
        await _reloadScoreAndLiveEventsBatched();
      },
    );
  }

  Future<void> _removeLastOfType(MatchEventEnum type) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isExternal) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack(l10n.matchMustLoginRegisterGoals, error: true);
      return;
    }
    final typeDb = type.toString().split('.').last;
    final uc = context.read<GetLatestMatchEventByDbTypeUseCase>();
    final latest = await uc(matchId: _match.id, typeDbValue: typeDb);
    final ev = latest.fold((_) => null, (e) => e);
    if (ev == null) {
      _showSnack(l10n.matchNoCounterToRemove, error: true);
      return;
    }
    final deleteMatchEventUseCase = context.read<DeleteMatchEventUseCase>();
    final result = await deleteMatchEventUseCase(
      ev,
      authState.user,
      widget.team.id,
    );
    await result.fold<Future<void>>(
      (failure) async {
        _showSnack(failure.message, error: true);
      },
      (_) async {
        await _reloadScoreAndLiveEventsBatched();
      },
    );
  }

  Future<Map<int, double>?> _queryPlayerRatingsMap() async {
    try {
      final uc = context.read<GetPlayerRatingEventRowsUseCase>();
      final result = await uc(_match.id);
      return result.fold((_) => null, (events) {
        final Map<int, double> newRatings = {};
        final teamScoring = context
            .read<TeamScoringConfigStorage>()
            .load(_match.teamId);
        for (final player in _convokedPlayers) {
          newRatings[player.id] = calculatePlayerRating(
            player.id,
            events,
            teamScoring: teamScoring,
          );
        }
        return newRatings;
      });
    } catch (e) {
      debugPrint('Error calculating player ratings: $e');
      return null;
    }
  }

  Future<void> _recalculatePlayerRatings() async {
    final map = await _queryPlayerRatingsMap();
    if (map == null || !mounted) return;
    setState(() {
      _playerRatings = map;
    });
  }

  Future<void> _refreshDerivedMatchData({bool reloadFormation = false}) async {
    await _reloadScoreAndLiveEventsBatched();
    await _recalculatePlayerRatings();
    await _loadDisciplineStateFromEvents();
    if (reloadFormation && mounted) {
      await _loadLastFormationFromEvents();
    }
  }

  /// Recarga datos desde Supabase (marcador, campo, eventos). Usado al
  /// deslizar para abajo; relevante para externos que no modifican el partido.
  Future<void> _onRefreshMatchScreen() async {
    await _mergeMatchFromServer();
    if (!mounted) return;
    await _recalculatePlayerRatings();
    if (!mounted) return;
    await _loadLastFormationFromEvents();
    if (!mounted) return;
    await _loadPositionsFromEvents();
    if (!mounted) return;
    await _loadDisciplineStateFromEvents();
    if (!mounted) return;
  }

  Future<void> _loadLiveEvents() async {
    final rows = await _queryLiveEventsFiltered();
    if (rows == null || !mounted) return;
    setState(() {
      _liveEvents = rows;
    });
  }

  /// PostgREST puede devolver enteros como [num]; evita fallos de `as int?` en el build.
  int? _dynToInt(dynamic v) => supabaseInt(v);

  String? _dynToStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Une variantes como scoreGoal, score_goal, enums en español, etc.
  String _canonicalEventTypeKey(dynamic raw) => canonicalMatchEventTypeKey(raw);

  /// Amarilla: contorno / fila amarilla. Roja o doble amarilla (expulsado): rojo.
  MatchPlayerDisciplineHighlight _playerDisciplineHighlight(int playerId) {
    var yellows = 0;
    var hasRed = false;
    for (final row in _liveEvents) {
      final p1 = supabaseInt(row['player_id1']);
      if (p1 != playerId) {
        continue;
      }
      final key = _canonicalEventTypeKey(row['type']);
      if (key == 'yellowcard') {
        yellows++;
      } else if (key == 'redcard') {
        hasRed = true;
      }
    }
    if (_sentOffPlayerIds.contains(playerId) || hasRed || yellows >= 2) {
      return MatchPlayerDisciplineHighlight.red;
    }
    if (yellows >= 1) {
      return MatchPlayerDisciplineHighlight.yellow;
    }
    return MatchPlayerDisciplineHighlight.none;
  }

  /// 1 = primera parte, 2 = segunda. Sin ancla de inicio 2ª: todo se trata como 1ª.
  int _eventMatchHalf(Map<String, dynamic> row, DateTime? secondHalfStart) {
    final r = MatchLiveTimelineRow.fromPostgresMap(
      Map<String, dynamic>.from(row),
    );
    return MatchLiveTimelineFilter.eventHalf(r, secondHalfStart);
  }

  /// Etiqueta de minuto: en descuento, [reglamentario]+[added] (p. ej. 45+2, 90+1).
  String _formatLiveEventMinuteLine(int minute, int half) {
    final h = _firstHalfDurationMinutesForCategory();
    if (half == 1) {
      if (minute > h) {
        return "$h+${minute - h}'";
      }
      return "$minute'";
    }
    final endReg = 2 * h;
    if (minute > endReg) {
      return "$endReg+${minute - endReg}'";
    }
    return "$minute'";
  }

  String _liveEventMinuteLabel(
    AppLocalizations l10n,
    Map<String, dynamic> row,
    int minute,
    int half,
  ) {
    final n = _dynToStr(row['note']);
    if (n != null && n.contains('prematch')) {
      return l10n.matchLiveMinuteSquad;
    }
    return _formatLiveEventMinuteLine(minute, half);
  }

  DateTime? _resolvedSecondHalfStart() {
    final rows = _liveEvents
        .map(
          (m) => MatchLiveTimelineRow.fromPostgresMap(
                Map<String, dynamic>.from(m),
              ),
        )
        .toList();
    return MatchLiveTimelineFilter.resolveSecondHalfStart(rows);
  }

  Future<List<Map<String, dynamic>>?> _queryLiveEventsFiltered() async {
    try {
      final uc = context.read<GetMatchLiveTimelineMapsUseCase>();
      final result = await uc(matchId: _match.id);
      return result.fold((_) => null, (rows) => rows);
    } catch (e) {
      debugPrint('Error loading live events: $e');
      return null;
    }
  }

  Future<Set<int>?> _querySentOffIdsFromEvents() async {
    try {
      final uc = context.read<GetMatchSentOffPlayerIdsUseCase>();
      final result = await uc(_match.id);
      return result.fold((_) => null, (s) => s);
    } catch (e) {
      debugPrint('Error querying discipline: $e');
      return null;
    }
  }

  /// Un solo [setState] tras registrar acción de jugador (menos parpadeo / scroll).
  Future<void> _refreshAfterPlayerAction({
    required MatchEventEnum type,
    required Player player,
  }) async {
    final needsScore =
        type == MatchEventEnum.scoreGoal ||
        type == MatchEventEnum.concedeGoal ||
        type == MatchEventEnum.ownGoal;
    final needsShots =
        type == MatchEventEnum.shot || type == MatchEventEnum.rivalShot;
    final needsDiscipline =
        type == MatchEventEnum.yellowCard || type == MatchEventEnum.redCard;
    final needsStatsAgg = needsScore ||
        needsShots ||
        type == MatchEventEnum.foul ||
        type == MatchEventEnum.yellowCard ||
        type == MatchEventEnum.redCard;

    final prevSentOff = Set<int>.from(_sentOffPlayerIds);

    final fRatings = _queryPlayerRatingsMap();
    final fLive = _queryLiveEventsFiltered();
    final Future<MatchEventAggregates?>? fAgg =
        needsStatsAgg ? _queryEventAggregatesFromEvents() : null;
    final Future<Set<int>?>? fDisc = needsDiscipline
        ? _querySentOffIdsFromEvents()
        : null;

    final ratings = await fRatings;
    final live = await fLive;
    final agg = fAgg != null ? await fAgg : null;
    final sentOff = fDisc != null ? await fDisc : null;

    if (!mounted) return;
    if (ratings == null || live == null) {
      await _refreshDerivedMatchData();
      return;
    }
    if (needsStatsAgg && agg == null) {
      await _refreshDerivedMatchData();
      return;
    }
    if (needsDiscipline && sentOff == null) {
      await _refreshDerivedMatchData();
      return;
    }

    setState(() {
      if (agg != null) {
        _applyEventAggregates(agg);
      }
      _playerRatings = ratings;
      _liveEvents = live;
      if (sentOff != null) {
        _sentOffPlayerIds
          ..clear()
          ..addAll(sentOff);
        final cleared = List<Player?>.from(_positionPlayers);
        for (int i = 0; i < cleared.length; i++) {
          final p = cleared[i];
          if (p != null && _sentOffPlayerIds.contains(p.id)) {
            cleared[i] = null;
          }
        }
        _positionPlayers = cleared;
        if (_selectedPlayer != null &&
            _sentOffPlayerIds.contains(_selectedPlayer!.id)) {
          _selectedPlayer = null;
        }
      }
    });

    if (sentOff != null &&
        needsDiscipline &&
        sentOff.difference(prevSentOff).isNotEmpty) {
      unawaited(_persistCurrentPositionsToMatchLineup());
    }
    if (needsDiscipline &&
        mounted &&
        !prevSentOff.contains(player.id) &&
        _sentOffPlayerIds.contains(player.id)) {
      unawaited(_showCardExpulsionSnack(player));
    }
  }

  Future<void> _showCardExpulsionSnack(Player player) async {
    try {
      final uc = context.read<GetPlayerCardSummaryForMatchPlayerUseCase>();
      final summaryResult = await uc(
        matchId: _match.id,
        playerId: player.id,
      );

      int yellowCount = 0;
      bool hasRed = false;
      summaryResult.fold((_) {}, (s) {
        yellowCount = s.yellowCount;
        hasRed = s.hasRed;
      });

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      _showSnackBarRich(
        error: true,
        spans: [
          ...playerNameSpanList(
            player,
            const TextStyle(color: Colors.white),
            mode: PlayerNameTextMode.matchShort,
          ),
          TextSpan(
            text: yellowCount >= 2 && !hasRed
                ? l10n.matchSentOffDoubleYellow
                : l10n.matchSentOffSimple,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error showing card expulsion snack: $e');
    }
  }

  Player? _playerFromRoster(int? id) {
    if (id == null) return null;
    for (final p in _convokedPlayers) {
      if (p.id == id) return p;
    }
    return null;
  }

  String _displayStatusChangeNote(String? note, AppLocalizations l10n) {
    if (note == null || note.isEmpty) return l10n.matchLivePeriodFallback;
    switch (note.trim()) {
      case 'Inicio 1ª parte':
      case 'Inicio 1a parte':
        return l10n.matchNoteFirstHalfStart;
      case 'Descanso':
        return l10n.matchStatusHalfTime;
      case 'Inicio 2ª parte':
      case 'Inicio 2a parte':
        return l10n.matchNoteSecondHalfStart;
      case 'Final del partido':
        return l10n.matchNoteMatchFinished;
      default:
        return note;
    }
  }

  String _displayConcededGoalNote(String? note, AppLocalizations l10n) {
    if (note == null || note.isEmpty) return l10n.matchLiveConcededDefault;
    if (note == 'Gol del rival') return l10n.matchOpponentGoal;
    return note;
  }

  List<InlineSpan> _liveEventDescriptionSpans(
    AppLocalizations l10n,
    Map<String, dynamic> row,
    TextStyle base,
  ) {
    final key = _canonicalEventTypeKey(row['type']);
    final note = _dynToStr(row['note']);
    final p1 = _dynToInt(row['player_id1']);
    final p2 = _dynToInt(row['player_id2']);
    final rawLabel = row['type']?.toString() ?? '';

    List<InlineSpan> dorsalSpans(int? id) {
      final pl = _playerFromRoster(id);
      if (pl == null) {
        return [
          TextSpan(
            text: id != null ? l10n.matchUnknownPlayerId(id) : '—',
          ),
        ];
      }
      return playerDorsalNameSpanList(pl, base);
    }

    switch (key) {
      case 'formation':
        final f = (note != null && note.trim().isNotEmpty) ? note.trim() : null;
        return [
          TextSpan(
            text: f != null
                ? l10n.matchLiveFormationLine(f)
                : l10n.matchLiveFormationRegistered,
          ),
        ];
      case 'substitution':
        if (p1 == null) {
          return [TextSpan(text: rawLabel)];
        }
        if (p2 == null) {
          return [
            TextSpan(text: l10n.matchLiveSubstitutionEnters),
            ...dorsalSpans(p1),
            TextSpan(text: l10n.matchLiveSubstitutionToFreeSlot),
          ];
        }
        return [
          TextSpan(text: l10n.matchLiveSubstitutionEnters),
          ...dorsalSpans(p1),
          TextSpan(text: l10n.matchLiveSubstitutionLeaves),
          ...dorsalSpans(p2),
        ];
      case 'statuschange':
        return [
          TextSpan(
            text: (note != null && note.isNotEmpty)
                ? _displayStatusChangeNote(note, l10n)
                : l10n.matchLivePeriodFallback,
          ),
        ];
      case 'scoregoal':
        final out = <InlineSpan>[
          TextSpan(text: l10n.matchLiveGoalBy),
          ...dorsalSpans(p1),
        ];
        if (p2 != null) {
          out.add(TextSpan(text: l10n.matchLiveAssistOpening));
          out.addAll(dorsalSpans(p2));
          out.add(TextSpan(text: l10n.matchLiveAssistClosing));
        }
        return out;
      case 'concedegoal':
        return [
          TextSpan(text: _displayConcededGoalNote(note, l10n)),
        ];
      case 'owngoal':
        return [
          TextSpan(text: l10n.matchLiveOwnGoal),
          ...dorsalSpans(p1),
        ];
      case 'yellowcard':
        return [
          TextSpan(text: l10n.matchLiveYellowCard),
          ...dorsalSpans(p1),
        ];
      case 'redcard':
        return [
          TextSpan(text: l10n.matchLiveRedCard),
          ...dorsalSpans(p1),
        ];
      case 'goodsave':
        return [
          TextSpan(text: l10n.matchLiveGoodSave),
          ...dorsalSpans(p1),
        ];
      case 'shot':
        return [
          TextSpan(text: l10n.matchLiveShot),
          ...dorsalSpans(p1),
        ];
      case 'foul':
        return [
          TextSpan(text: l10n.matchLiveFoul),
          ...dorsalSpans(p1),
        ];
      case 'cantada':
        return [
          TextSpan(text: l10n.matchLiveCantada),
          ...dorsalSpans(p1),
        ];
      case 'keypass':
        return [
          TextSpan(text: l10n.matchLiveKeyPass),
          ...dorsalSpans(p1),
        ];
      case 'goodpass':
        return [
          TextSpan(text: l10n.matchLiveGoodPass),
          ...dorsalSpans(p1),
        ];
      case 'badpass':
        return [
          TextSpan(text: l10n.matchLiveBadPass),
          ...dorsalSpans(p1),
        ];
      case 'goodplay':
        return [
          TextSpan(text: l10n.matchLiveGoodPlay),
          ...dorsalSpans(p1),
        ];
      case 'badplay':
        return [
          TextSpan(text: l10n.matchLiveBadPlay),
          ...dorsalSpans(p1),
        ];
      case 'ballrecovery':
        return [
          TextSpan(text: l10n.matchLiveBallRecovery),
          ...dorsalSpans(p1),
        ];
      default:
        if (note != null && note.isNotEmpty) {
          return [
            TextSpan(
              text: l10n.matchLiveEventLine(
                key.isEmpty ? l10n.matchLiveEvent : rawLabel,
                note,
              ),
            ),
          ];
        }
        return [
          TextSpan(text: key.isEmpty ? l10n.matchLiveEvent : rawLabel),
        ];
    }
  }

  /// Avatar de la fila de eventos: tarjetas con fondo amarillo/rojo acorde.
  (Color background, Color iconColor) _liveEventListAvatarColors(
    ColorScheme scheme,
    String canonicalKey,
  ) {
    switch (canonicalKey) {
      case 'yellowcard':
        return (const Color(0xFFFFC107), Colors.black87);
      case 'redcard':
        return (scheme.error, scheme.onError);
      case 'foul':
      case 'rivalfoul':
        return (kMatchFoulListAvatarBackground, kMatchFoulListAvatarForeground);
      default:
        return (scheme.surfaceContainerHigh, scheme.primary);
    }
  }

  IconData _iconForLiveEventKey(String canonicalKey) {
    switch (canonicalKey) {
      case 'scoregoal':
      case 'concedegoal':
      case 'owngoal':
        return Icons.sports_soccer;
      case 'yellowcard':
        return Icons.style;
      case 'redcard':
        return Icons.style;
      case 'substitution':
        return Icons.swap_horiz;
      case 'formation':
        return Icons.grid_view;
      case 'statuschange':
        return Icons.schedule;
      case 'goodsave':
        return Icons.sports_handball;
      case 'shot':
        return Icons.adjust;
      case 'cantada':
        return Icons.sentiment_dissatisfied;
      case 'keypass':
        return Icons.alt_route;
      case 'goodpass':
        return Icons.north_east;
      case 'badpass':
        return Icons.south_west;
      case 'goodplay':
        return Icons.thumb_up_outlined;
      case 'badplay':
        return Icons.thumb_down_outlined;
      case 'ballrecovery':
        return Icons.cached;
      default:
        return Icons.event_note;
    }
  }

  Future<void> _onLiveEventTapped(Map<String, dynamic> row) async {
    if (_isExternal) {
      return;
    }
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack(AppLocalizations.of(context)!.matchLoginRequiredShort, error: true);
      return;
    }

    final minute = resolveMatchEventMinute(
      Map<String, dynamic>.from(row),
    );
    final half = _eventMatchHalf(row, _resolvedSecondHalfStart());
    final l10nDialogMin = AppLocalizations.of(context)!;
    final minuteLine = _liveEventMinuteLabel(l10nDialogMin, row, minute, half);
    final minutePrefix = minute != 0 ||
            (_dynToStr(row['note'])?.contains('prematch') ?? false)
        ? '$minuteLine · '
        : '';
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.matchDeleteEvent),
          content: Text.rich(
            TextSpan(
              style: baseStyle,
              children: [
                if (minutePrefix.isNotEmpty) TextSpan(text: minutePrefix),
                ..._liveEventDescriptionSpans(l10n, row, baseStyle),
                TextSpan(text: '\n\n${l10n.matchDeleteEventQuestion}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.actionConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      final normalized = Map<String, dynamic>.from(row);
      normalized['id'] = _dynToInt(row['id']) ?? 0;
      normalized['match_id'] = _dynToInt(row['match_id']) ?? _match.id;
      normalized['player_id1'] = _dynToInt(row['player_id1']);
      normalized['player_id2'] = _dynToInt(row['player_id2']);
      normalized['minute'] = _dynToInt(row['minute']) ?? 0;

      final event = MatchEvent.fromSupabaseMap(normalized);
      final deleteMatchEventUseCase = context.read<DeleteMatchEventUseCase>();
      final result = await deleteMatchEventUseCase(
        event,
        authState.user,
        widget.team.id,
      );

      if (!mounted) return;

      await result.fold<Future<void>>(
        (failure) async {
          _showSnack(failure.message, error: true);
        },
        (_) async {
          final reloadFormation =
              _canonicalEventTypeKey(row['type']) == 'formation';
          await _refreshDerivedMatchData(reloadFormation: reloadFormation);
          if (mounted) {
            _showSnack(AppLocalizations.of(context)!.matchEventDeleted);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.matchEventDeleteFail, error: true);
      }
    }
  }

  Future<void> _loadLastFormationFromEvents() async {
    try {
      final uc = context.read<GetLatestFormationNoteByMatchUseCase>();
      final result = await uc(_match.id);
      await result.fold<Future<void>>(
        (_) async {},
        (formationNote) async {
          final formation = formationNote?.trim();
          if (formation == null || !_formationOptions.containsKey(formation)) {
            return;
          }

          if (!mounted) return;
          final outfieldLines = _formationOptions[formation]!;
          final newFormationLines = [1, ...outfieldLines];
          final totalPositions = newFormationLines.fold<int>(
            0,
            (sum, value) => sum + value,
          );

          setState(() {
            _selectedFormation = formation;
            _formationLines = newFormationLines;
            if (_positionPlayers.length != totalPositions) {
              _positionPlayers = List<Player?>.filled(totalPositions, null);
            }
          });
        },
      );
    } catch (_) {
      // Si falla, mantenemos la formación actual
    }
  }

  Future<bool> _confirmAction(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.actionConfirm),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSnackBarRich({
    required List<InlineSpan> spans,
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text.rich(
          TextSpan(
            style: const TextStyle(color: Colors.white),
            children: spans,
          ),
        ),
        backgroundColor: error ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _updateStartersInMatchLineup() async {
    try {
      final starterIds = _positionPlayers
          .where((p) => p != null)
          .map((p) => p!.id)
          .toSet()
          .toList();

      if (starterIds.isEmpty) return;

      final uc = context.read<ApplyMatchLineupStartersUseCase>();
      final res = await uc(matchId: _match.id, starterPlayerIds: starterIds);
      await res.fold<Future<void>>(
        (f) async {
          debugPrint('Error al marcar titulares: ${f.message}');
        },
        (_) async {
          if (mounted) await _loadMatchLineupsForMatchState();
        },
      );
    } catch (e) {
      // No rompemos la UI si falla; solo registramos el error.
      debugPrint('Error updating starters in match_lineup: $e');
    }
  }

  Future<void> _saveFormationEvent() async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        // Si no hay usuario autenticado, no guardamos el evento
        return;
      }

      final saveMatchEventUseCase = context.read<SaveMatchEventUseCase>();
      final minute = _currentMatchMinute();
      final event = MatchEvent(
        id: 0,
        matchId: _match.id,
        playerId1: null,
        playerId2: null,
        minute: minute,
        type: MatchEventEnum.formation,
        note: _selectedFormation,
      );

      await saveMatchEventUseCase(event, authState.user, widget.team.id);
      if (mounted) await _loadLiveEvents();
    } catch (e) {
      // No rompemos la UI por un error al guardar la formación
      debugPrint('Error saving formation event: $e');
    }
  }

  Future<void> _saveSubstitutionEvent({
    required Player playerIn,
    Player? playerOut,
  }) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        return;
      }

      final saveMatchEventUseCase = context.read<SaveMatchEventUseCase>();

      final inNumber = playerIn.number?.toString() ?? '-';
      final outNumber = playerOut?.number?.toString() ?? '-';

      final int minute;
      final String note;
      if (_phase == _MatchPhase.notStarted) {
        // Antes del inicio: minuto 0; [resolveMatchEventMinute] lee min: de la nota.
        minute = 0;
        note = 'In:$inNumber,out:$outNumber,prematch,min:0';
      } else if (_phase == _MatchPhase.halfTime) {
        // Fin reglamentario 1.ª parte (p. ej. 25' / 45'), no 0' ni solo "halftime".
        minute = _firstHalfDurationMinutesForCategory();
        note = 'In:$inNumber,out:$outNumber,halftime,min:$minute';
      } else {
        minute = _currentMatchMinute();
        note = 'In:$inNumber,out:$outNumber,min:$minute';
      }

      final event = MatchEvent(
        id: 0,
        matchId: _match.id,
        playerId1: playerIn.id,
        playerId2: playerOut?.id,
        minute: minute,
        type: MatchEventEnum.substitution,
        note: note,
      );

      final result = await saveMatchEventUseCase(
        event,
        authState.user,
        widget.team.id,
      );
      await result.fold<Future<void>>(
        (failure) async {
          if (!mounted) return;
          _showSnack(failure.message, error: true);
          debugPrint('Sustitución no guardada: ${failure.message}');
        },
        (_) async {
          if (mounted) await _loadLiveEvents();
        },
      );
    } catch (e) {
      debugPrint('Error saving substitution event: $e');
    }
  }

  Future<void> _onAddGoal({required bool ourTeam}) async {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack(l10n.matchMustLoginRegisterGoals, error: true);
      return;
    }

    final confirmed = await _confirmAction(
      l10n.matchConfirmGoalTitle,
      ourTeam
          ? l10n.matchConfirmAddGoalOur
          : l10n.matchConfirmAddGoalRival,
    );
    if (!confirmed) return;

    try {
      if (ourTeam) {
        _showSnack(
          l10n.matchGoalsOurTeamFromField,
          error: true,
        );
        return;
      }

      final saveMatchEventUseCase = context.read<SaveMatchEventUseCase>();
      final minute = _currentMatchMinute();
      final event = MatchEvent(
        id: 0,
        matchId: _match.id,
        playerId1: null,
        playerId2: null,
        minute: minute,
        type: MatchEventEnum.concedeGoal,
        note: 'Gol del rival',
      );

      final result = await saveMatchEventUseCase(
        event,
        authState.user,
        widget.team.id,
      );

      if (!mounted) return;

      await result.fold<Future<void>>(
        (failure) async {
          _showSnack(failure.message, error: true);
        },
        (_) async {
          await _refreshDerivedMatchData();
          if (mounted) {
            _showSnack(l10n.matchOpponentGoalRegisteredOk);
          }
        },
      );
    } catch (e) {
      _showSnack(l10n.matchGoalSaveFail, error: true);
    }
  }

  Future<void> _loadConvocationPlayers() async {
    setState(() {
      _loadingPlayers = true;
      _loadError = null;
    });

    // 1) Intentamos obtener los ids de los jugadores convocados
    // desde la tabla match_lineup. Si falla (por ejemplo por
    // permisos en Supabase), seguiremos mostrando al menos
    // todos los jugadores del equipo como fallback.
    Set<int> playerIds = {};
    try {
      final idsUc = context.read<FetchConvokedPlayerIdsForMatchUseCase>();
      final idsRes = await idsUc(_match.id);
      playerIds = idsRes.fold((_) => <int>{}, (s) => s);
    } catch (e) {
      debugPrint('Error loading match_lineup for convocation: $e');
    }

    // 2) Cargamos los jugadores del equipo y filtramos por los
    // ids convocados (si los tenemos). Si no tenemos ids (por
    // error en match_lineup), mostramos toda la plantilla.
    try {
      final getPlayersByTeamUseCase = context.read<GetPlayersByTeamUseCase>();
      final playersResult = await getPlayersByTeamUseCase(widget.team.id);

      await playersResult.fold<Future<void>>(
        (failure) async {
          if (!mounted) return;
          setState(() {
            _loadError = failure.message;
            _loadingPlayers = false;
          });
        },
        (players) async {
          List<Player> convoked;
          if (playerIds.isEmpty) {
            convoked = List<Player>.from(players);
          } else {
            convoked = players.where((p) => playerIds.contains(p.id)).toList();
          }

          convoked.sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

          if (!mounted) return;
          setState(() {
            _convokedPlayers
              ..clear()
              ..addAll(convoked);
            _loadingPlayers = false;
          });

          _restorePositionsIfSaved();
          if (!mounted) return;
          await _loadPositionsFromEvents();
          if (!mounted) return;
          await _loadDisciplineStateFromEvents();
          if (!mounted) return;
          await _recalculatePlayerRatings();
          if (!mounted) return;
          await _loadLiveEvents();
        },
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _loadError = l10n.matchConvocationLoadError;
        _loadingPlayers = false;
      });
    }
  }

  Future<void> _loadPositionsFromEvents() async {
    try {
      final uc = context.read<FetchMatchLineupPositionsUseCase>();
      final res = await uc(_match.id);

      if (!mounted) return;

      await res.fold<Future<void>>(
        (_) async {},
        (assignments) async {
          final List<Player?> newPositions = List<Player?>.filled(
            _positionPlayers.length,
            null,
          );

          for (final a in assignments) {
            final playerId = a.playerId;
            final pos = a.positionIndex;
            if (pos < 0 || pos >= newPositions.length) continue;

            final player = _convokedPlayers.firstWhere(
              (p) => p.id == playerId,
              orElse: () => const Player(teamId: 0, firstName: ''),
            );

            if (player.id != 0) {
              newPositions[pos] = player;
            }
          }

          if (!mounted) return;
          setState(() {
            _positionPlayers = newPositions;
          });
        },
      );
    } catch (e) {
      debugPrint('Error loading positions from match_lineup: $e');
    }
  }

  Future<void> _loadDisciplineStateFromEvents() async {
    final sentOff = await _querySentOffIdsFromEvents();
    if (sentOff == null || !mounted) return;

    setState(() {
      _sentOffPlayerIds
        ..clear()
        ..addAll(sentOff);

      final cleared = List<Player?>.from(_positionPlayers);
      for (int i = 0; i < cleared.length; i++) {
        final p = cleared[i];
        if (p != null && _sentOffPlayerIds.contains(p.id)) {
          cleared[i] = null;
        }
      }
      _positionPlayers = cleared;

      if (_selectedPlayer != null &&
          _sentOffPlayerIds.contains(_selectedPlayer!.id)) {
        _selectedPlayer = null;
      }
    });
    unawaited(_persistCurrentPositionsToMatchLineup());
  }

  String _bottomButtonLabel(AppLocalizations l10n) {
    switch (_phase) {
      case _MatchPhase.notStarted:
        return l10n.matchStartGameButton;
      case _MatchPhase.firstHalf:
        return l10n.matchHalfTimeButton;
      case _MatchPhase.halfTime:
        return l10n.matchResumeGameButton;
      case _MatchPhase.secondHalf:
        return l10n.matchEndGame;
    }
  }

  String _phaseDisplayLabel(AppLocalizations l10n) {
    if (_match.status == MatchStatus.finished) {
      return l10n.matchStatusFinished;
    }
    switch (_phase) {
      case _MatchPhase.notStarted:
        return l10n.matchPhaseNotStarted;
      case _MatchPhase.firstHalf:
        return l10n.matchStatusFirstHalf;
      case _MatchPhase.halfTime:
        return l10n.matchStatusHalfTime;
      case _MatchPhase.secondHalf:
        return l10n.matchStatusSecondHalf;
    }
  }

  Widget _buildMatchClockDisplay(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.layoutScale;
    final mainSeconds = _displayClockMainTotalSeconds();
    final extraSeconds = _extraClockSeconds();
    if (extraSeconds <= 0) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _formatTime(mainSeconds),
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 44 * s,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(mainSeconds),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(width: 8 * s),
          Text(
            '+',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.outline,
            ),
          ),
          SizedBox(width: 8 * s),
          Text(
            _formatTime(extraSeconds),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPlayerActionRequested(Player player) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isExternal) {
      _showSnack(
        l10n.matchSpectatorNoPlayerActions,
        error: true,
      );
      return;
    }
    final selection = await showMatchPlayerActionModal(
      context,
      player,
      teamId: widget.team.id,
    );

    if (selection == null) return;

    final label = selection.confirmLabel;
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.matchConfirmAction),
          content: Text.rich(
            TextSpan(
              style: baseStyle,
              children: [
                TextSpan(text: l10n.matchRegisterActionIntro(label)),
                ...playerNameSpanList(
                  player,
                  baseStyle,
                  mode: PlayerNameTextMode.matchShort,
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.actionConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await _savePlayerScoringSelection(player, selection);
  }

  Future<void> _savePlayerScoringSelection(
    Player player,
    MatchPlayerScoringSelection selection,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        _showSnack(l10n.matchActionRegisterLogin, error: true);
        return;
      }

      final saveMatchEventUseCase = context.read<SaveMatchEventUseCase>();
      final minute = _currentMatchMinute();
      final kind = selection.kind;

      if (kind is MatchPlayerScoringSaveGoal) {
        await _savePlayerGoalWithAssist(
          player: player,
          minute: minute,
          authUser: authState.user,
          saveMatchEventUseCase: saveMatchEventUseCase,
        );
        return;
      }
      if (kind is! MatchPlayerScoringSaveEvent) {
        return;
      }

      final type = kind.type;
      final note = kind.note;
      final event = MatchEvent(
        id: 0,
        matchId: _match.id,
        playerId1: player.id,
        playerId2: null,
        minute: minute,
        type: type,
        note: note,
      );

      final result = await saveMatchEventUseCase(
        event,
        authState.user,
        widget.team.id,
      );

      await result.fold<Future<void>>(
        (failure) async {
          _showSnack(failure.message, error: true);
        },
        (_) async {
          await _refreshAfterPlayerAction(type: type, player: player);
          if (mounted) {
            _showSnackBarRich(
              spans: [
                TextSpan(text: l10n.matchActionRegisteredPrefix),
                ...playerNameSpanList(
                  player,
                  const TextStyle(color: Colors.white),
                  mode: PlayerNameTextMode.matchShort,
                ),
              ],
            );
          }
        },
      );
    } catch (e) {
      _showSnack(l10n.matchActionRegisterFail, error: true);
    }
  }

  Future<Player?> _selectAssistPlayer(Player scorer) async {
    return showDialog<Player?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final onFieldIds = _positionPlayers
            .where((p) => p != null)
            .map((p) => p!.id)
            .toSet();

        final assistCandidates = _convokedPlayers
            .where((p) => p.id != scorer.id && onFieldIds.contains(p.id))
            .toList();

        final dlgL10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(dlgL10n.matchPickAssistant),
          content: SizedBox(
            width: 320,
            height: 320,
            child: Column(
              children: [
                ListTile(
                  title: Text(dlgL10n.matchNoAttendanceOption),
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: assistCandidates.length,
                    itemBuilder: (context, index) {
                      final p = assistCandidates[index];
                      return ListTile(
                        title: PlayerDorsalNameText(player: p),
                        onTap: () => Navigator.of(ctx).pop(p),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(dlgL10n.actionCancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePlayerGoalWithAssist({
    required Player player,
    required int minute,
    required tfg_auth.AuthUser authUser,
    required SaveMatchEventUseCase saveMatchEventUseCase,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final assistPlayer = await _selectAssistPlayer(player);

      // Un solo evento de gol con goleador (playerId1) y, si aplica,
      // asistente (playerId2).
      final goalEvent = MatchEvent(
        id: 0,
        matchId: _match.id,
        playerId1: player.id,
        playerId2: assistPlayer?.id,
        minute: minute,
        type: MatchEventEnum.scoreGoal,
        note: 'Gol',
      );

      final goalResult = await saveMatchEventUseCase(
        goalEvent,
        authUser,
        widget.team.id,
      );

      await goalResult.fold<Future<void>>(
        (failure) async {
          _showSnack(l10n.matchGoalSaveFail, error: true);
        },
        (_) async {
          await _refreshAfterPlayerAction(
            type: MatchEventEnum.scoreGoal,
            player: player,
          );
          if (mounted) {
            _showSnackBarRich(
              spans: [
                TextSpan(text: l10n.matchGoalRegisteredPrefix),
                ...playerNameSpanList(
                  player,
                  const TextStyle(color: Colors.white),
                  mode: PlayerNameTextMode.matchShort,
                ),
              ],
            );
          }
        },
      );
    } catch (e) {
      _showSnack(l10n.matchGoalSaveFail, error: true);
    }
  }

  Future<void> _onBottomButtonPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final loadingCubit = context.read<LoadingCubit>();

    if (_phase == _MatchPhase.notStarted) {
      if (!_allPositionsFilled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchFillAllPositionsBeforeStart),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchMustLoginStart),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final confirmed = await _confirmAction(
        l10n.matchConfirmStartTitle,
        l10n.matchConfirmStartBody,
      );
      if (!confirmed) return;

      final startMatchUseCase = context.read<StartMatchUseCase>();
      final startTime = DateTime.now();
      if (loadingCubit.state) return;
      loadingCubit.start();
      final result = await startMatchUseCase(_match, authState.user);
      loadingCubit.stop();

      await result.fold<Future<void>>(
        (failure) async {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) async {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.matchStartedOk),
              backgroundColor: Colors.green,
            ),
          );
          _saveCurrentLineup();
          // Persistimos la posición actual de cada jugador en match_lineup.position
          await _persistCurrentPositionsToMatchLineup();
          // Actualizamos en BD qué jugadores empiezan como titulares.
          await _updateStartersInMatchLineup();
          if (!mounted) return;
          final lockInitialRes = await context
              .read<LockInitialLineupPositionsUseCase>()(_match.id);
          lockInitialRes.fold(
            (f) => debugPrint('Lock initial lineup: ${f.message}'),
            (_) {},
          );
          if (!mounted) return;
          // Formación al inicio: si nunca se abrió el selector, aún hace falta
          // un evento "formation" en match_events para estadísticas y detalle.
          await _saveFormationEvent();
          // Guardamos evento de inicio de partido / 1ª parte
          await _saveStatusChangeEvent(MatchStatus.firstHalf, 0);
          if (!mounted) return;
          setState(() {
            _match = Match(
              id: _match.id,
              teamId: _match.teamId,
              opponent: _match.opponent,
              goalsScored: _match.goalsScored,
              goalsConceded: _match.goalsConceded,
              date: startTime,
              hour:
                  '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
              status: MatchStatus.firstHalf,
              lineups: _match.lineups,
              isHome: _match.isHome,
            );
            _phase = _MatchPhase.firstHalf;
            _activeSegmentStartedAt = startTime;
            _clockFrozenSegmentSeconds = null;
          });
          _startTimer();
        },
      );
    } else if (_phase == _MatchPhase.firstHalf) {
      final confirmed = await _confirmAction(
        l10n.matchConfirmHalfTimeTitle,
        l10n.matchConfirmHalfTimeBody,
      );
      if (!confirmed) return;
      // Pasar a descanso: congelar el tiempo de la 1ª parte (ancla real, no un contador)
      {
        final start = _activeSegmentStartedAt;
        if (start != null) {
          _clockFrozenSegmentSeconds =
              (DateTime.now().difference(start).inSeconds).clamp(0, 1 << 20);
        } else {
          _clockFrozenSegmentSeconds = 0;
        }
        _activeSegmentStartedAt = null;
      }
      _isTimerRunning = false;
      _timer?.cancel();
      final minute = _currentMatchMinute();
      // Guardamos evento de cambio de estado a descanso
      _saveStatusChangeEvent(MatchStatus.halfTime, minute);
      setState(() {
        _phase = _MatchPhase.halfTime;
        _match = Match(
          id: _match.id,
          teamId: _match.teamId,
          opponent: _match.opponent,
          goalsScored: _match.goalsScored,
          goalsConceded: _match.goalsConceded,
          date: _match.date,
          hour: _match.hour,
          status: MatchStatus.halfTime,
          lineups: _match.lineups,
          isHome: _match.isHome,
        );
      });
      // Actualizar estado en BD a "halfTime"
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchMustLoginPause),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!loadingCubit.state) {
        loadingCubit.start();
        try {
          final applyHt = context.read<ApplyMatchHalfTimeStatusUseCase>();
          final htRes = await applyHt(_match.id);
          htRes.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(failure.message),
                  backgroundColor: Colors.red,
                ),
              );
            },
            (_) {},
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.matchStateUpdateFail),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          loadingCubit.stop();
        }
      }
    } else if (_phase == _MatchPhase.halfTime) {
      final confirmed = await _confirmAction(
        l10n.matchConfirmResumeTitle,
        l10n.matchConfirmResumeBody,
      );
      if (!confirmed) return;
      // Reanudar segunda parte
      final secondHalfStart = DateTime.now();
      setState(() {
        _clockFrozenSegmentSeconds = null;
        _activeSegmentStartedAt = secondHalfStart;
        _phase = _MatchPhase.secondHalf;
        _match = Match(
          id: _match.id,
          teamId: _match.teamId,
          opponent: _match.opponent,
          goalsScored: _match.goalsScored,
          goalsConceded: _match.goalsConceded,
          date: secondHalfStart,
          hour:
              '${secondHalfStart.hour.toString().padLeft(2, '0')}:${secondHalfStart.minute.toString().padLeft(2, '0')}',
          status: MatchStatus.secondHalf,
          lineups: _match.lineups,
          isHome: _match.isHome,
        );
      });
      _startTimer();

      // Guardamos evento de inicio de 2ª parte (minuto ~35)
      final minute = _currentMatchMinute();
      _saveStatusChangeEvent(MatchStatus.secondHalf, minute);

      // Actualizar estado en BD a "secondHalf"
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchMustLoginResume),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!loadingCubit.state) {
        loadingCubit.start();
        try {
          final apply2 = context.read<ApplyMatchSecondHalfStartedUseCase>();
          final shRes = await apply2(
            matchId: _match.id,
            secondHalfStart: secondHalfStart,
          );
          shRes.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(failure.message),
                  backgroundColor: Colors.red,
                ),
              );
            },
            (_) {},
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.matchStateUpdateFail),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          loadingCubit.stop();
        }
      }
    } else if (_phase == _MatchPhase.secondHalf) {
      // Terminar partido (el cronómetro sigue en tiempo real hasta confirmar).
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchMustLoginFinish),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final dlg = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(dlg.matchEndGame),
            content: Text(dlg.matchEndGameDialogBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(dlg.actionCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  dlg.matchEndGameAction,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      _isTimerRunning = false;
      _timer?.cancel();

      // Asegura en BD la disposición actual del campo para el detalle del partido.
      await _persistCurrentPositionsToMatchLineup();
      // Última formación (por si el usuario no usó nunca _changeFormation).
      await _saveFormationEvent();

      // Guardamos evento de final de partido (await: el cierre usa el evento
      // para calcular minutos y fin del partido en estadísticas acumuladas).
      final minute = _currentMatchMinute();
      await _saveStatusChangeEvent(MatchStatus.finished, minute);
      if (!mounted) return;

      final finishMatchUseCase = context.read<FinishMatchUseCase>();
      if (loadingCubit.state) return;
      loadingCubit.start();
      final result = await finishMatchUseCase(_match, authState.user);
      loadingCubit.stop();

      await result.fold<Future<void>>(
        (failure) async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) async {
          if (!mounted) return;
          final counts = await _queryEventAggregatesFromEvents();
          final finishedMatch = Match(
            id: _match.id,
            teamId: _match.teamId,
            opponent: _match.opponent,
            goalsScored: counts?.goalsScored ?? _match.goalsScored,
            goalsConceded: counts?.goalsConceded ?? _match.goalsConceded,
            date: _match.date,
            hour: _match.hour,
            status: MatchStatus.finished,
            lineups: _match.lineups,
            isHome: _match.isHome,
          );

          if (!mounted) return;
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
          final teamScoringConfigStorage =
              context.read<TeamScoringConfigStorage>();
          final loadErrorMessage =
              AppLocalizations.of(context)!.matchStatsLoadError;
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (ctx) => BlocProvider(
                create: (_) => MatchStatsCubit(
                  match: finishedMatch,
                  getPlayersByTeamUseCase: getPlayersByTeamUseCase,
                  getMatchEventsByMatchUseCase: getMatchEventsByMatchUseCase,
                  getMatchLineupsByMatchUseCase: getMatchLineupsByMatchUseCase,
                  getFirstFormationNoteByMatchUseCase:
                      getFirstFormationNoteByMatchUseCase,
                  getLatestFormationNoteByMatchUseCase:
                      getLatestFormationNoteByMatchUseCase,
                  getMatchEventAggregatesFromEventsUseCase:
                      getMatchEventAggregatesFromEventsUseCase,
                  teamScoringConfigStorage: teamScoringConfigStorage,
                  loadErrorMessage: loadErrorMessage,
                )..load(),
                child: MatchStatsPage(
                  match: finishedMatch,
                  ourTeamName: widget.team.name,
                  teamColorHex: widget.team.color,
                ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isExternal = _isExternal;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final s = context.layoutScale;
    final pagePad = AppResponsive.pageHorizontalPadding(context);
    final screenW = MediaQuery.sizeOf(context).width;

    return TeamBrandedScope(
      team: widget.team,
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.screenMatchLive,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: const [TeamQuickNavAppBarButton()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefreshMatchScreen,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pagePad, 12 * s, pagePad, 24 * s),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.all(16 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: scheme.primary),
                          SizedBox(width: 8 * s),
                          Expanded(
                            child: Text(
                              l10n.matchScoreAndTime,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isExternal && _phase == _MatchPhase.notStarted)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            l10n.matchSpectatorCannotStart,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        )
                      else
                        BlocBuilder<LoadingCubit, bool>(
                          builder: (context, isLoading) {
                            final schemeBtn = Theme.of(context).colorScheme;
                            return FilledButton(
                              onPressed: (isLoading || isExternal)
                                  ? null
                                  : _onBottomButtonPressed,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: schemeBtn.onPrimary,
                                      ),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _bottomButtonLabel(l10n),
                                        style: TextStyle(
                                          fontSize: 16 * s,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      const SizedBox(height: 14),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 20 * s,
                          horizontal: 12 * s,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  widget.team.name,
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${_match.goalsScored}',
                                        style: theme.textTheme.displaySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              height: 1,
                                              color: scheme.primary,
                                            ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8 * s,
                                        ),
                                        child: Text(
                                          '—',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                color: scheme.outline,
                                                fontWeight: FontWeight.w700,
                                                height: 1,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        '${_match.goalsConceded}',
                                        style: theme.textTheme.displaySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              height: 1,
                                              color: scheme.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _match.opponent,
                                  textAlign: TextAlign.start,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _phaseDisplayLabel(l10n),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: 30 * s,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -0.4,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10 * s),
                          Center(
                            child: ListenableBuilder(
                              listenable: _clockTick,
                              builder: (context, _) =>
                                  _buildMatchClockDisplay(context),
                            ),
                          ),
                        ],
                      ),
                      if (!isExternal) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.matchQuickScore,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                            foregroundColor: scheme.onError,
                          ),
                          onPressed: () => _onAddGoal(ourTeam: false),
                          icon: Icon(Icons.sports_soccer, size: 20 * s),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.matchOpponentGoal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: MatchLiveStatsPanel(
                  layoutScale: s,
                  readOnly: isExternal,
                  shotsOur: _shotsOur,
                  shotsRival: _shotsRival,
                  foulsOur: _foulsOur,
                  foulsRival: _foulsRival,
                  cornersOur: _cornersOur,
                  cornersRival: _cornersRival,
                  offsidesOur: _offsidesOur,
                  offsidesRival: _offsidesRival,
                  yellowOur: _yellowOur,
                  yellowRival: _yellowRival,
                  redOur: _redOur,
                  redRival: _redRival,
                  l10n: l10n,
                  onRemoveRivalShot: isExternal
                      ? null
                      : () => _removeLastOfType(MatchEventEnum.rivalShot),
                  onAddRivalShot: isExternal
                      ? null
                      : () => _saveManualCounterEvent(
                            type: MatchEventEnum.rivalShot,
                            note: l10n.matchEventRivalShot,
                          ),
                  onRemoveRivalFoul: isExternal
                      ? null
                      : () => _removeLastOfType(MatchEventEnum.rivalFoul),
                  onAddRivalFoul: isExternal
                      ? null
                      : () => _saveManualCounterEvent(
                            type: MatchEventEnum.rivalFoul,
                            note: 'Falta rival',
                          ),
                  onRemoveCorner: isExternal
                      ? null
                      : () => _removeLastOfType(MatchEventEnum.corner),
                  onAddCorner: isExternal
                      ? null
                      : () => _saveManualCounterEvent(
                            type: MatchEventEnum.corner,
                            note: 'Córner',
                          ),
                  onRemoveRivalCorner: isExternal
                      ? null
                      : () => _removeLastOfType(MatchEventEnum.rivalCorner),
                  onAddRivalCorner: isExternal
                      ? null
                      : () => _saveManualCounterEvent(
                            type: MatchEventEnum.rivalCorner,
                            note: 'Córner rival',
                          ),
                  onRemoveOffside: isExternal
                      ? null
                      : () => _removeLastOfType(MatchEventEnum.offside),
                  onAddOffside: isExternal
                      ? null
                      : () => _saveManualCounterEvent(
                            type: MatchEventEnum.offside,
                            note: l10n.matchEventOffside,
                          ),
                  onRemoveRivalOffside: isExternal
                      ? null
                      : () => _removeLastOfType(MatchEventEnum.rivalOffside),
                  onAddRivalOffside: isExternal
                      ? null
                      : () => _saveManualCounterEvent(
                            type: MatchEventEnum.rivalOffside,
                            note: l10n.matchEventRivalOffside,
                          ),
                  onRemoveRivalYellowCard: isExternal
                      ? null
                      : () => _removeLastOfType(
                            MatchEventEnum.rivalYellowCard,
                          ),
                  onAddRivalYellowCard: isExternal
                      ? null
                      : () => _saveManualCounterEvent(
                            type: MatchEventEnum.rivalYellowCard,
                            note: l10n.matchRivalYellowCardNote,
                          ),
                  onRemoveRivalRedCard: isExternal
                      ? null
                      : () => _removeLastOfType(
                            MatchEventEnum.rivalRedCard,
                          ),
                  onAddRivalRedCard: isExternal
                      ? null
                      : () => _saveManualCounterEvent(
                            type: MatchEventEnum.rivalRedCard,
                            note: l10n.matchRivalRedCardNote,
                          ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 14 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stadium_outlined, color: scheme.primary),
                          SizedBox(width: 8 * s),
                          Expanded(
                            child: Text(
                              l10n.matchFieldAndFormation,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isExternal)
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Chip(
                                  label: Text(
                                    _selectedFormation,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12 * s,
                                    ),
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.65),
                                  side: BorderSide.none,
                                ),
                              ),
                            )
                          else
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonalIcon(
                                    onPressed: _showFormationPicker,
                                    icon: Icon(
                                      Icons.grid_view_rounded,
                                      size: 18 * s,
                                    ),
                                    label: Text(
                                      _selectedFormation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 10 * s),
                      ExcludeSemantics(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: screenW - 2 * pagePad,
                            ),
                            child: RepaintBoundary(
                              child: MatchFieldWithFormation(
                              formationLines: _formationLines,
                              formationLayoutKey: _selectedFormation,
                              positionPlayers: _positionPlayers,
                              benchPlayers: _benchPlayers,
                              selectedPlayer: _selectedPlayer,
                              sentOffPlayerIds: _sentOffPlayerIds,
                              currentPlayersOnField: _currentPlayersOnField,
                              maxPlayersOnField: _maxPlayersOnField,
                              showSnack: _showSnack,
                              onPositionsChanged: (newPositions) {
                                setState(() {
                                  _positionPlayers = newPositions;
                                  _selectedPlayer = null;
                                });
                                _persistCurrentPositionsToMatchLineup();
                              },
                              onSubstitutionRequested: (playerIn, playerOut) {
                                _saveSubstitutionEvent(
                                  playerIn: playerIn,
                                  playerOut: playerOut,
                                );
                              },
                              onPlayerActionRequested:
                                  _onPlayerActionRequested,
                              readOnly: isExternal,
                              playerDiscipline: _playerDisciplineHighlight,
                            ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_showLiveLastEventHighlight) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildLiveLastEventBlinkBanner(
                    theme,
                    scheme,
                    isExternal,
                    l10n,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4 * s, 8 * s, 4 * s, 12 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12 * s),
                        child: Row(
                          children: [
                            Icon(Icons.groups, color: scheme.primary),
                            SizedBox(width: 8 * s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.matchSquadTitle,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    isExternal
                                        ? l10n.matchSquadHintSpectator
                                        : l10n.matchSquadHintCoach,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      MatchConvocationTable(
                        loading: _loadingPlayers,
                        error: _loadError,
                        convokedPlayers: _convokedPlayers,
                        positionPlayers: _positionPlayers,
                        selectedPlayer: _selectedPlayer,
                        sentOffPlayerIds: _sentOffPlayerIds,
                        playerRatings: _playerRatings,
                        minutesPlayedByPlayerId: _canSeeConvokedMinutesPlayed
                            ? _computeMinutesPlayedForConvoked()
                            : null,
                        scrollingChild: true,
                        readOnly: isExternal,
                        playerDiscipline: _playerDisciplineHighlight,
                        onPlayerTap: (player, isSentOff) {
                          if (isExternal) return;
                          if (isSentOff) {
                            _showSnack(
                              l10n.matchPlayerSentOffCannotReturn,
                              error: true,
                            );
                            return;
                          }
                          setState(() {
                            if (_selectedPlayer?.id == player.id) {
                              _selectedPlayer = null;
                            } else {
                              _selectedPlayer = player;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                  padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 10 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: scheme.primary),
                          SizedBox(width: 8 * s),
                          Expanded(
                            child: Text(
                              l10n.matchEventsTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isExternal
                            ? l10n.matchEventsHintSpectator
                            : l10n.matchEventsHintCoach,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_liveEvents.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            l10n.matchEventsEmpty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        for (int i = 0; i < _liveEvents.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          Builder(
                            builder: (context) {
                              final evKey = _canonicalEventTypeKey(
                                _liveEvents[i]['type'],
                              );
                              final isFoulRow = isMatchFoulCanonicalKey(evKey);
                              final avatar = _liveEventListAvatarColors(
                                scheme,
                                evKey,
                              );
                              return DecoratedBox(
                                decoration: isFoulRow
                                    ? BoxDecoration(
                                        color: kMatchFoulListAvatarBackground
                                            .withValues(alpha: 0.85),
                                        border: Border(
                                          left: BorderSide(
                                            color: kMatchFoulListAvatarForeground
                                                .withValues(alpha: 0.65),
                                            width: 3,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      )
                                    : const BoxDecoration(),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isExternal
                                        ? null
                                        : () => _onLiveEventTapped(
                                            _liveEvents[i],
                                            ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: avatar.$1,
                                            child: isFoulRow
                                                ? MatchWhistleIcon(
                                                    size: 18,
                                                    color: avatar.$2,
                                                  )
                                                : Icon(
                                                    _iconForLiveEventKey(
                                                      evKey,
                                                    ),
                                                    size: 18,
                                                    color: avatar.$2,
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text.rich(
                                                  TextSpan(
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                    children:
                                                        _liveEventDescriptionSpans(
                                                      l10n,
                                                      _liveEvents[i],
                                                      theme
                                                          .textTheme
                                                          .bodyMedium!
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  softWrap: true,
                                                ),
                                                Text(
                                                  () {
                                                    final rowMap =
                                                        _liveEvents[i];
                                                    final m =
                                                        resolveMatchEventMinute(
                                                      Map<String, dynamic>.from(
                                                        rowMap,
                                                      ),
                                                    );
                                                    final half = _eventMatchHalf(
                                                      rowMap,
                                                      _resolvedSecondHalfStart(),
                                                    );
                                                    return _liveEventMinuteLabel(
                                                      l10n,
                                                      rowMap,
                                                      m,
                                                      half,
                                                    );
                                                  }(),
                                                  style: theme.textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: scheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isExternal)
                                            Icon(
                                              Icons.delete_outline,
                                              size: 22,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                    ],
                  ),
                ),
              ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
