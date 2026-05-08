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
import 'package:football_manager/domain/utils/match_minutes_utils.dart';
import 'package:football_manager/domain/repositories/i_match_spectator_realtime.dart';
import 'package:football_manager/domain/entities/match_live_timeline_row.dart';
import 'package:football_manager/domain/services/match_live_timeline_filter.dart';
import 'package:football_manager/domain/usecase/match/apply_match_half_time_status_use_case.dart';
import 'package:football_manager/domain/usecase/match/apply_match_lineup_starters_use_case.dart';
import 'package:football_manager/domain/usecase/match/apply_match_second_half_started_use_case.dart';
import 'package:football_manager/domain/usecase/match/fetch_convoked_player_ids_for_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/fetch_match_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/fetch_remote_match_status_use_case.dart';
import 'package:football_manager/domain/usecase/match/finish_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/persist_match_lineup_positions_use_case.dart';
import 'package:football_manager/domain/usecase/match/start_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_match_lineups_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_formation_note_by_match_use_case.dart';
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
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_convocation_table.dart';
import 'package:football_manager/presentation/match/widgets/match_live_stats_panel.dart';
import 'package:football_manager/presentation/match/widgets/match_field_with_formation.dart';
import 'package:football_manager/presentation/match/widgets/match_player_action_modal.dart';
import 'package:football_manager/presentation/match/pages/match_stats_page.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/core/theme/app_responsive.dart';
import 'package:football_manager/core/theme/team_brand_theme.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/cubit/team_context_cubit.dart';
import 'package:football_manager/presentation/team/widgets/team_quick_nav_bubble.dart';

enum _MatchPhase { notStarted, firstHalf, halfTime, secondHalf }

class _SavedLineupState {
  final String formationKey;
  final List<int?> playerIds;

  /// Snapshot local de formacion y jugadores por posicion.
  /// Lo hace guardando clave de formacion y lista de ids.
  const _SavedLineupState({
    required this.formationKey,
    required this.playerIds,
  });
}

/// Pantalla principal para gestionar un partido en vivo.
/// Permite controlar estado, formacion y eventos.
class MatchManagerPage extends StatefulWidget {
  final Team team;
  final Match match;

  /// Crea la pantalla con el equipo y el partido a gestionar.
  const MatchManagerPage({super.key, required this.team, required this.match});

  /// Crea el estado asociado.
  @override
  State<MatchManagerPage> createState() => _MatchManagerPageState();
}

class _MatchManagerPageState extends State<MatchManagerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static final Map<int, _SavedLineupState> _savedLineups = {};
  static final Map<int, DateTime> _matchStartTimes = {};
  late Match _match;
  final List<Player> _convokedPlayers = [];
  bool _loadingPlayers = true;
  String? _loadError;

  // Media en tiempo real por jugador (0-10, base 5).
  Map<int, double> _playerRatings = {};

  // Jugadores expulsados (roja o doble amarilla).
  final Set<int> _sentOffPlayerIds = {};
  // Minuto de expulsión por jugador: una vez registrado no se recalcula.
  final Map<int, int> _expulsionMinuteByPlayer = {};

  /// Tiros a puerta (eventos `shot` / `rivalShot` / `scoreGoal`), derivados de [match_events].
  int _shotsOur = 0;
  int _shotsRival = 0;

  /// Faltas propias (eventos `falta` por jugador) y del rival (`rivalFoul` manual).
  int _foulsOur = 0;
  int _foulsRival = 0;

  /// Córners (eventos `corner` / `rivalCorner`, manuales).
  int _cornersOur = 0;
  int _cornersRival = 0;

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
  int _elapsedSeconds = 0;
  _MatchPhase _phase = _MatchPhase.notStarted;
  bool _isTimerRunning = false;

  // Último cambio local de jugadores en campo, para suavizar refrescos realtime.
  DateTime? _lastLocalLineupChangeAt;

  IMatchSpectatorRealtime? _spectatorRealtime;
  Timer? _spectatorRealtimeDebounce;
  AppLifecycleState? _previousAppLifecycle;

  late AnimationController _lastEventBlinkController;

  /// Indica si el usuario es espectador externo.
  /// Lo hace leyendo el rol desde [AuthCubit].
  bool get _isExternal {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return false;
    return authState.user.teamRoles[widget.team.id] == UserRole.external;
  }

  /// Indica si el usuario puede ver todos los eventos del partido.
  /// Lo hace comprobando permisos de admin/superadmin.
  bool get _canSeeAllEvents {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return false;
    final role = authState.user.teamRoles[widget.team.id];
    return role?.hasAdminPrivileges ?? false;
  }

  /// Minutos disputados en la convocatoria: solo admins / superadmins.
  /// Indica si puede ver minutos disputados de la convocatoria.
  /// Lo hace comprobando privilegios de administrador.
  bool get _canSeeConvokedMinutesPlayed {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return false;
    final role = authState.user.teamRoles[widget.team.id];
    return role?.hasAdminPrivileges ?? false;
  }

  /// Calcula minutos jugados para los convocados.
  /// Lo hace reconstruyendo eventos y aplicando reglas de sustituciones.
  Map<int, int> _computeMinutesPlayedForConvoked() {
    final events = _liveEvents
        .map((m) => MatchEvent.fromSupabaseMap(Map<String, dynamic>.from(m)))
        .toList();

    final int? endOverride = _match.status == MatchStatus.finished
        ? null
        : _minutesCutoffForCurrentStatus(events);

    // Obtener minutos de expulsión por jugador. Empezamos por los minutos
    // ya registrados localmente para evitar recálculos posteriores.
    final expulsionMinuteByPlayer = Map<int, int>.from(
      _expulsionMinuteByPlayer,
    );
    final expulsedIds = _getExpulsedPlayerIds();

    final sortedEvents = List<MatchEvent>.from(events);
    sortMatchEventsByTime(sortedEvents);

    for (final e in sortedEvents) {
      final pid = e.playerId1;
      if (pid == null || !expulsedIds.contains(pid)) continue;

      if (e.type == MatchEventEnum.redCard) {
        final minute = e.minute;
        expulsionMinuteByPlayer.putIfAbsent(pid, () => minute);
        _expulsionMinuteByPlayer.putIfAbsent(pid, () => minute);
      } else if (e.type == MatchEventEnum.yellowCard) {
        final nextYellowCount = (_countYellowCardsForPlayer(
          sortedEvents,
          pid,
          e.minute,
        ));
        if (nextYellowCount >= 2) {
          final minute = e.minute;
          expulsionMinuteByPlayer.putIfAbsent(pid, () => minute);
          _expulsionMinuteByPlayer.putIfAbsent(pid, () => minute);
        }
      }
    }

    final starterById = <int, bool>{};
    for (final l in _match.lineups) {
      starterById[l.playerId] = l.isStarting;
    }

    final map = <int, int>{};
    for (final p in _convokedPlayers) {
      final isStarter = starterById[p.id] ?? false;

      // Si el jugador está expulsado, usar su minuto de expulsión como límite.
      final playerEndMinute = expulsionMinuteByPlayer[p.id] ?? endOverride;

      map[p.id] = minutesPlayedForPlayer(
        events: events,
        playerId: p.id,
        isStarter: isStarter,
        overrideMatchEndMinute: playerEndMinute,
      );
    }
    return map;
  }

  /// Registra en `_expulsionMinuteByPlayer` los minutos de expulsión detectados
  /// en una lista de filas de eventos (rows). No sobreescribe minutos ya guardados.
  void _recordExpulsionMinutesFromRows(List<Map<String, dynamic>> rows) {
    final events = rows
        .map((m) => MatchEvent.fromSupabaseMap(Map<String, dynamic>.from(m)))
        .toList();
    sortMatchEventsByTime(events);

    final yellowCounts = <int, int>{};
    for (final e in events) {
      final pid = e.playerId1;
      if (pid == null) continue;
      if (e.type == MatchEventEnum.redCard) {
        _expulsionMinuteByPlayer.putIfAbsent(pid, () => e.minute);
        continue;
      }
      if (e.type == MatchEventEnum.yellowCard) {
        final next = (yellowCounts[pid] ?? 0) + 1;
        yellowCounts[pid] = next;
        if (next >= 2) {
          _expulsionMinuteByPlayer.putIfAbsent(pid, () => e.minute);
        }
      }
    }
  }

  /// Cuenta tarjetas amarillas de un jugador hasta un minuto específico.
  int _countYellowCardsForPlayer(
    List<MatchEvent> sortedEvents,
    int playerId,
    int upToMinute,
  ) {
    int count = 0;
    for (final e in sortedEvents) {
      if (e.minute > upToMinute) break;
      if (e.playerId1 == playerId && e.type == MatchEventEnum.yellowCard) {
        count++;
      }
    }
    return count;
  }

  /// Minuto de corte para el cálculo de minutos jugados.
  /// En partido vivo usa el cronómetro actual; al finalizar usa los eventos.
  int _minutesCutoffForCurrentStatus(List<MatchEvent> events) {
    if (_match.status == MatchStatus.notStarted) {
      return 0;
    }

    if (_match.status == MatchStatus.firstHalf ||
        _match.status == MatchStatus.secondHalf ||
        _match.status == MatchStatus.halfTime) {
      return _currentMatchMinute();
    }

    int maxMinute = 0;
    for (final e in events) {
      if (e.minute > maxMinute) {
        maxMinute = e.minute;
      }
    }

    return maxMinute;
  }

  /// Detecta jugadores expulsados (roja o segunda amarilla) en los eventos.
  /// Retorna un set con los IDs de jugadores expulsados.
  Set<int> _getExpulsedPlayerIds() {
    final expulsedIds = <int>{};
    final yellowCounts = <int, int>{};

    final sortedEvents = List<MatchEvent>.from(
      _liveEvents
          .map((m) => MatchEvent.fromSupabaseMap(Map<String, dynamic>.from(m)))
          .toList(),
    );
    sortMatchEventsByTime(sortedEvents);

    for (final e in sortedEvents) {
      final pid = e.playerId1;
      if (pid == null) continue;

      if (e.type == MatchEventEnum.redCard) {
        expulsedIds.add(pid);
      } else if (e.type == MatchEventEnum.yellowCard) {
        final count = (yellowCounts[pid] ?? 0) + 1;
        yellowCounts[pid] = count;
        if (count >= 2) {
          expulsedIds.add(pid);
        }
      }
    }

    return expulsedIds;
  }

  /// Remueve jugadores expulsados del campo y persiste posiciones.
  /// Los expulsados no pueden seguir jugando: se les quita la posición
  /// para que el campo muestre un jugador menos.
  void _removeExpulsedPlayersFromField([Set<int>? expulsedIds]) {
    final expelled = expulsedIds ?? _effectiveSentOffPlayerIds();
    if (expelled.isEmpty) return;

    final hasExpulsed = _positionPlayers.any(
      (p) => p != null && expelled.contains(p.id),
    );
    if (!hasExpulsed) return;

    setState(() {
      for (int i = 0; i < _positionPlayers.length; i++) {
        final p = _positionPlayers[i];
        if (p != null && expelled.contains(p.id)) {
          _positionPlayers[i] = null;
        }
      }
    });

    // Guardar cambios de posiciones localmente y en BD.
    _saveCurrentLineup();
    unawaited(_persistCurrentPositionsToMatchLineup());
  }

  /// Inicializa estado, formaciones y suscripciones necesarias.
  /// Lo hace preparando formacion, timers y carga inicial.
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final prev = _previousAppLifecycle;
    _previousAppLifecycle = state;

    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (prev != AppLifecycleState.paused &&
        prev != AppLifecycleState.hidden &&
        prev != AppLifecycleState.inactive) {
      return;
    }

    _resyncTimerFromMatchClock();
    unawaited(_syncMatchMetaFromServer());
  }

  /// Indica si se muestra el banner del ultimo evento.
  /// Lo hace segun el estado actual del partido.
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

  /// Construye el banner animado del ultimo evento.
  /// Lo hace con un AnimatedBuilder y estilos pulsantes.
  Widget _buildLiveLastEventBlinkBanner(
    ThemeData theme,
    ColorScheme scheme,
    bool isExternal,
    AppLocalizations l10n,
    Map<String, dynamic> row,
  ) {
    final baseStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w600,
    );
    final minute = _dynToInt(row['minute']) ?? 0;
    final half = _eventMatchHalf(row, _resolvedSecondHalfStart());
    final minuteLine = _formatLiveEventMinuteLine(minute, half);
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
        final accentGlow = scheme.secondary.withValues(
          alpha: 0.06 + 0.14 * breathe,
        );

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
                          child: Icon(
                            _iconForLiveEventKey(
                              _canonicalEventTypeKey(row['type']),
                            ),
                            color: scheme.primary,
                            size: 22,
                          ),
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

  /// Libera timers, animaciones y realtime al salir.
  /// Lo hace cancelando timers y desuscribiendo.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastEventBlinkController.dispose();
    _timer?.cancel();
    _spectatorRealtimeDebounce?.cancel();
    final rt = _spectatorRealtime;
    _spectatorRealtime = null;
    if (rt != null) {
      unawaited(rt.unsubscribe());
    }
    super.dispose();
  }

  /// Inicia el cronometro del partido.
  /// Lo hace con Timer.periodic y aumenta segundos.
  void _startTimer() {
    _isTimerRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isTimerRunning || !mounted) return;
      final nextElapsed = _elapsedSecondsFromCurrentHalfStart();
      if (nextElapsed == _elapsedSeconds) return;
      setState(() {
        _elapsedSeconds = nextElapsed;
      });
    });
  }

  /// Segundos transcurridos desde el inicio real de la parte actual.
  /// Lo hace comparando la hora actual con [_match.date].
  int _elapsedSecondsFromCurrentHalfStart() {
    final startTime = _matchStartTimes[_match.id] ?? _match.date;
    final diff = DateTime.now().difference(startTime).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Recalibra el cronómetro con la hora real al volver del fondo.
  /// Lo hace releyendo el inicio de la parte actual y reanudando el timer.
  void _resyncTimerFromMatchClock() {
    if (!mounted) return;

    switch (_match.status) {
      case MatchStatus.firstHalf:
      case MatchStatus.secondHalf:
        final nextElapsed = _elapsedSecondsFromCurrentHalfStart();
        setState(() {
          _elapsedSeconds = nextElapsed;
        });
        _startTimer();
        break;
      case MatchStatus.notStarted:
      case MatchStatus.halfTime:
      case MatchStatus.finished:
        _isTimerRunning = false;
        _timer?.cancel();
        break;
    }
  }

  /// Carga datos iniciales del partido y arranca realtime.
  /// Lo hace encadenando cargas y luego suscribiendo.
  Future<void> _bootstrapMatchInitialData() async {
    if (!mounted) return;
    await Future.wait<void>([
      _reloadScoreFromEvents(),
      _loadLastFormationFromEvents(),
    ]);
    if (!mounted) return;
    await _loadConvocationPlayers();
    if (!mounted) return;
    _subscribeSpectatorRealtime();
  }

  /// Externo: cambios en BD (eventos, alineación, estado del partido) sin tirar del listado.
  /// Lo hace suscribiendose a un canal realtime del partido.
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
    port.subscribeToMatch(mid, onRemoteChange);
  }

  /// Agrupa cambios realtime para evitar demasiadas recargas.
  /// Lo hace con un debounce corto.
  void _scheduleSpectatorRealtimeRefresh() {
    _spectatorRealtimeDebounce?.cancel();
    _spectatorRealtimeDebounce = Timer(const Duration(milliseconds: 400), () {
      _spectatorRealtimeDebounce = null;
      if (!mounted) return;
      unawaited(_onRefreshMatchScreen());
    });
  }

  /// Sincroniza el estado del partido desde el servidor.
  /// Lo hace consultando el caso de uso y ajustando fase/timer.
  Future<void> _syncMatchMetaFromServer() async {
    try {
      final uc = context.read<FetchRemoteMatchStatusUseCase>();
      final result = await uc(_match.id);
      await result.fold<Future<void>>((_) async {}, (status) async {
        if (!mounted || status == null || status == _match.status) return;

        setState(() {
          _match = Match(
            id: _match.id,
            teamId: _match.teamId,
            opponent: _match.opponent,
            goalsScored: _match.goalsScored,
            goalsConceded: _match.goalsConceded,
            date: _match.date,
            hour: _match.hour,
            status: status,
            lineups: _match.lineups,
            isHome: _match.isHome,
          );
          switch (status) {
            case MatchStatus.notStarted:
              _phase = _MatchPhase.notStarted;
              _isTimerRunning = false;
              _timer?.cancel();
              break;
            case MatchStatus.firstHalf:
              _phase = _MatchPhase.firstHalf;
              break;
            case MatchStatus.halfTime:
              _phase = _MatchPhase.halfTime;
              _isTimerRunning = false;
              _timer?.cancel();
              break;
            case MatchStatus.secondHalf:
              _phase = _MatchPhase.secondHalf;
              break;
            case MatchStatus.finished:
              _isTimerRunning = false;
              _timer?.cancel();
              break;
          }
        });

        if (status == MatchStatus.firstHalf ||
            status == MatchStatus.secondHalf) {
          if (mounted && !_isTimerRunning) {
            _initializeTimer();
          }
        }
      });
    } catch (e) {
      debugPrint('Error syncing match meta: $e');
    }
  }

  /// Indica si la categoria usa futbol 7.
  /// Lo hace buscando palabras clave en la categoria.
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

  /// Inicializa las formaciones disponibles segun categoria.
  /// Lo hace asignando mapas distintos para futbol 7 u 11.
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

  /// Inicializa el cronometro con la hora de inicio real.
  /// Lo hace calculando el diff y arrancando el timer.
  void _initializeTimer() {
    _elapsedSeconds = _elapsedSecondsFromCurrentHalfStart();
    _startTimer();
  }

  /// Indica si todas las posiciones del campo estan asignadas.
  /// Lo hace verificando que no haya nulos.
  bool get _allPositionsFilled =>
      _positionPlayers.isNotEmpty &&
      _positionPlayers.every((player) => player != null);

  /// Devuelve el numero actual de jugadores en el campo.
  /// Lo hace contando posiciones no nulas.
  int _currentPlayersOnField() {
    final sentOff = _effectiveSentOffPlayerIds();
    return _positionPlayers
        .where((p) => p != null && !sentOff.contains(p.id))
        .length;
  }

  /// Calcula el maximo de jugadores permitidos segun expulsiones.
  /// Lo hace restando expulsados al total de huecos.
  int _maxPlayersOnField() {
    final totalPositions = _positionPlayers.length;
    final expelledCount = _effectiveSentOffPlayerIds().length;
    final maxAllowed = totalPositions - expelledCount;
    return maxAllowed < 0 ? 0 : maxAllowed;
  }

  /// Guarda en memoria la formacion y asignaciones actuales.
  /// Lo hace creando un snapshot en _savedLineups.
  void _saveCurrentLineup() {
    final playerIds = _positionPlayers.map((p) => p?.id).toList();
    _savedLineups[_match.id] = _SavedLineupState(
      formationKey: _selectedFormation,
      playerIds: playerIds,
    );
  }

  /// Persiste posiciones actuales en la tabla match_lineup.
  /// Lo hace enviando un mapa de jugador -> posicion.
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

  /// Cambia la formacion y ajusta el tamanio de posiciones.
  /// Lo hace recalculando lineas y copiando asignaciones existentes.
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

  /// Abre un dialogo para seleccionar formacion.
  /// Lo hace mostrando las opciones y aplicando la eleccion.
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

  /// Restaura posiciones guardadas si coinciden con la formacion.
  /// Lo hace reconstruyendo la lista desde ids pendientes.
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

  /// Formatea segundos en mm:ss para el cronometro.
  /// Lo hace con division y padLeft.
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Duracion reglamentaria de la primera parte segun categoria.
  /// Lo hace con reglas por nombre de categoria.
  int _firstHalfDurationMinutesForCategory() {
    final cat = widget.team.category.toLowerCase();

    if (cat.contains('prebenjamin') || cat.contains('prebenjamín')) {
      return 25;
    }

    if (cat.contains('benjamin') || cat.contains('benjamín')) {
      return 30;
    }

    if (cat.contains('alevin') || cat.contains('alevín')) {
      return 35;
    }

    if (cat.contains('infantil')) {
      return 40;
    }

    if (cat.contains('cadete') ||
        cat.contains('juvenil') ||
        cat.contains('senior')) {
      return 45;
    }

    // Valor por defecto razonable si la categoría no coincide
    return 35;
  }

  /// Minuto actual de partido segun fase y cronometro.
  /// Lo hace sumando la primera parte cuando toca.
  int _currentMatchMinute() {
    final baseMinutes = _elapsedSeconds ~/ 60;
    if (_phase == _MatchPhase.secondHalf) {
      // Sumamos la duración de la 1ª parte según categoría
      return baseMinutes + _firstHalfDurationMinutesForCategory();
    }
    return baseMinutes;
  }

  /// Duracion de una parte en segundos.
  /// Lo hace convirtiendo minutos reglamentarios a segundos.
  int _halfDurationSeconds() => _firstHalfDurationMinutesForCategory() * 60;

  /// Cronómetro: tiempo transcurrido de la parte (sube desde 0:00), topeado al reglamentario.
  /// Segundos de juego reglamentarios en la parte actual.
  /// Lo hace acotando el cronometro al limite.
  int _mainClockSeconds() {
    final limit = _halfDurationSeconds();
    final value = _elapsedSeconds <= limit ? _elapsedSeconds : limit;
    return value < 0 ? 0 : value;
  }

  /// Segundos de descuento sobre el limite reglamentario.
  /// Lo hace restando el limite cuando se excede.
  int _extraClockSeconds() {
    final limit = _halfDurationSeconds();
    if (_elapsedSeconds <= limit) return 0;
    return _elapsedSeconds - limit;
  }

  /// Guarda un evento de cambio de estado (inicio, descanso, fin).
  /// Lo hace creando un MatchEvent y llamando al caso de uso.
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

  /// Consulta agregados de eventos (goles, tiros, etc.).
  /// Lo hace llamando al caso de uso y manejando errores.
  Future<MatchEventAggregates?> _queryEventAggregatesFromEvents() async {
    try {
      final uc = context.read<GetMatchEventAggregatesFromEventsUseCase>();
      final result = await uc(_match.id);
      return result.fold((_) => null, (a) => a);
    } catch (_) {
      return null;
    }
  }

  /// Recarga el marcador y contadores derivados desde eventos.
  /// Lo hace leyendo agregados y actualizando el estado.
  Future<void> _reloadScoreFromEvents() async {
    final agg = await _queryEventAggregatesFromEvents();
    if (agg == null || !mounted) return;
    setState(() {
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
    });
  }

  /// Aplica un cambio optimista al marcador mientras llega la recarga.
  /// Lo hace actualizando solo goles a favor y en contra.
  void _applyOptimisticScoreChange({
    int goalsScoredDelta = 0,
    int goalsConcededDelta = 0,
  }) {
    if (!mounted) return;

    if (goalsScoredDelta == 0 && goalsConcededDelta == 0) {
      return;
    }

    setState(() {
      _match = Match(
        id: _match.id,
        teamId: _match.teamId,
        opponent: _match.opponent,
        goalsScored: (_match.goalsScored + goalsScoredDelta).clamp(0, 999),
        goalsConceded: (_match.goalsConceded + goalsConcededDelta).clamp(
          0,
          999,
        ),
        date: _match.date,
        hour: _match.hour,
        status: _match.status,
        lineups: _match.lineups,
        isHome: _match.isHome,
      );
    });
  }

  /// Registra un evento manual (tiros, faltas, corners).
  /// Lo hace creando un evento sin jugador asociado.
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
        await _reloadScoreFromEvents();
        if (mounted) await _loadLiveEvents();
      },
    );
  }

  /// Elimina el ultimo evento del tipo indicado.
  /// Lo hace consultando el ultimo registro y borrandolo.
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
        await _reloadScoreFromEvents();
        if (mounted) await _loadLiveEvents();
      },
    );
  }

  /// Calcula el mapa de medias por jugador.
  /// Lo hace leyendo eventos y aplicando la formula de rating.
  Future<Map<int, double>?> _queryPlayerRatingsMap() async {
    try {
      final uc = context.read<GetPlayerRatingEventRowsUseCase>();
      final result = await uc(_match.id);
      return result.fold((_) => null, (events) {
        final Map<int, double> newRatings = {};
        for (final player in _convokedPlayers) {
          newRatings[player.id] = calculatePlayerRating(player.id, events);
        }
        return newRatings;
      });
    } catch (e) {
      debugPrint('Error calculating player ratings: $e');
      return null;
    }
  }

  /// Recalcula medias y actualiza el estado local.
  /// Lo hace llamando a _queryPlayerRatingsMap y setState.
  Future<void> _recalculatePlayerRatings() async {
    final map = await _queryPlayerRatingsMap();
    if (map == null || !mounted) return;
    setState(() {
      _playerRatings = map;
    });
  }

  /// Refresca datos derivados: marcador, ratings, disciplina, eventos.
  /// Lo hace invocando varias cargas en cadena.
  Future<void> _refreshDerivedMatchData({bool reloadFormation = false}) async {
    await _reloadScoreFromEvents();
    await _recalculatePlayerRatings();
    await _loadDisciplineStateFromEvents();
    await _loadLiveEvents();
    if (reloadFormation && mounted) {
      await _loadLastFormationFromEvents();
    }
  }

  /// Recarga datos desde Supabase (marcador, campo, eventos). Usado al
  /// deslizar para abajo; relevante para externos que no modifican el partido.
  /// Recarga completa desde Supabase al hacer pull-to-refresh.
  /// Lo hace encadenando cargas y sincronizando estado externo.
  Future<void> _onRefreshMatchScreen() async {
    await _reloadScoreFromEvents();
    if (!mounted) return;
    await _recalculatePlayerRatings();
    if (!mounted) return;
    await _loadLiveEvents();
    if (!mounted) return;
    await _loadLastFormationFromEvents();
    if (!mounted) return;
    final canReloadPositions =
        _isExternal ||
        _lastLocalLineupChangeAt == null ||
        DateTime.now().difference(_lastLocalLineupChangeAt!) >
            const Duration(milliseconds: 1500);
    if (canReloadPositions) {
      await _loadPositionsFromEvents();
      if (!mounted) return;
    }
    await _loadDisciplineStateFromEvents();
    if (!mounted) return;
    if (_isExternal) {
      await _syncMatchMetaFromServer();
    }
  }

  /// Carga la lista de eventos en vivo filtrados.
  /// Lo hace consultando el caso de uso y setState.
  Future<void> _loadLiveEvents() async {
    final rows = await _queryLiveEventsFiltered();
    if (rows == null || !mounted) return;
    final derivedSentOff = _deriveSentOffFromRows(rows);
    // Registrar minutos de expulsión detectados en estos rows (no sobreescribe).
    _recordExpulsionMinutesFromRows(rows);
    setState(() {
      _liveEvents = rows;
      _sentOffPlayerIds
        ..clear()
        ..addAll(derivedSentOff);
      if (_selectedPlayer != null &&
          derivedSentOff.contains(_selectedPlayer!.id)) {
        _selectedPlayer = null;
      }
    });

    // Garantiza que toda expulsión deja hueco vacío inmediatamente.
    _removeExpulsedPlayersFromField(_effectiveSentOffPlayerIds());
  }

  /// PostgREST puede devolver enteros como [num]; evita fallos de `as int?` en el build.
  /// Convierte valores dinamicos a int evitando errores de cast.
  /// Lo hace delegando en utilidades de Supabase.
  int? _dynToInt(dynamic v) => supabaseInt(v);

  /// Normaliza un valor dinamico a String no vacio.
  /// Lo hace con trim y devuelve null si queda vacio.
  String? _dynToStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Une variantes como scoreGoal, score_goal, enums en español, etc.
  /// Normaliza variantes de tipo de evento a una clave canonica.
  /// Lo hace con canonicalMatchEventTypeKey.
  String _canonicalEventTypeKey(dynamic raw) => canonicalMatchEventTypeKey(raw);

  /// 1 = primera parte, 2 = segunda. Sin ancla de inicio 2ª: todo se trata como 1ª.
  /// Determina en que parte ocurre un evento de linea temporal.
  /// Lo hace delegando en MatchLiveTimelineFilter.
  int _eventMatchHalf(Map<String, dynamic> row, DateTime? secondHalfStart) {
    final r = MatchLiveTimelineRow.fromPostgresMap(
      Map<String, dynamic>.from(row),
    );
    return MatchLiveTimelineFilter.eventHalf(r, secondHalfStart);
  }

  /// Etiqueta de minuto: en descuento, [reglamentario]+[added] (p. ej. 45+2, 90+1).
  /// Formatea el minuto con descuento (45+2, 90+1).
  /// Lo hace usando la duracion reglamentaria segun categoria.
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

  /// Resuelve el instante de inicio de la segunda parte.
  /// Lo hace inspeccionando eventos de linea temporal.
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

  /// Consulta la linea temporal filtrada desde BD.
  /// Lo hace llamando al caso de uso dedicado.
  Future<List<Map<String, dynamic>>?> _queryLiveEventsFiltered() async {
    try {
      final uc = context.read<GetMatchLiveTimelineMapsUseCase>();
      final result = await uc(matchId: _match.id, includeAll: true);
      return result.fold((_) => null, (rows) => rows);
    } catch (e) {
      debugPrint('Error loading live events: $e');
      return null;
    }
  }

  /// Consulta jugadores expulsados segun eventos.
  /// Lo hace llamando al caso de uso correspondiente.
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

  /// Deriva los ids expulsados a partir de los eventos en memoria [_liveEvents].
  /// Esto sirve como fallback cuando la consulta remota falla o tarda.
  Set<int> _deriveSentOffFromLiveEvents() {
    return _deriveSentOffFromRows(_liveEvents);
  }

  Set<int> _deriveSentOffFromRows(List<Map<String, dynamic>> rows) {
    final sentOff = <int>{};
    final yellowCounts = <int, int>{};
    for (final row in rows) {
      final key = _canonicalEventTypeKey(row['type']);
      final pid = _dynToInt(row['player_id1']);
      if (pid == null) continue;
      if (key == 'redcard') {
        sentOff.add(pid);
        continue;
      }
      if (key == 'yellowcard') {
        final next = (yellowCounts[pid] ?? 0) + 1;
        yellowCounts[pid] = next;
        if (next >= 2) sentOff.add(pid);
      }
    }
    return sentOff;
  }

  Set<int> _effectiveSentOffPlayerIds() {
    final effective = <int>{
      ..._sentOffPlayerIds,
      ..._deriveSentOffFromLiveEvents(),
    };
    if (_convokedPlayers.isEmpty) {
      return effective;
    }
    final convokedIds = _convokedPlayers.map((p) => p.id).toSet();
    effective.removeWhere((id) => !convokedIds.contains(id));
    return effective;
  }

  /// Un solo [setState] tras registrar acción de jugador (menos parpadeo / scroll).
  /// Lo hace agrupando consultas y actualizando el estado una sola vez.
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
    final needsStatsAgg =
        needsScore || needsShots || type == MatchEventEnum.foul;

    final prevSentOff = Set<int>.from(_sentOffPlayerIds);

    final fRatings = _queryPlayerRatingsMap();
    final fLive = _queryLiveEventsFiltered();
    final Future<MatchEventAggregates?>? fAgg = needsStatsAgg
        ? _queryEventAggregatesFromEvents()
        : null;
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

    // Registrar minutos de expulsión detectados en la carga live.
    _recordExpulsionMinutesFromRows(live);

    setState(() {
      if (agg != null) {
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
      }
      _playerRatings = ratings;
      _liveEvents = live;
      if (sentOff != null) {
        final effective = <int>{...sentOff, ..._deriveSentOffFromRows(live)};
        _sentOffPlayerIds
          ..clear()
          ..addAll(effective);
        if (_selectedPlayer != null &&
            _sentOffPlayerIds.contains(_selectedPlayer!.id)) {
          _selectedPlayer = null;
        }
      }
    });
    // Quitar automáticamente del campo a los expulsados.
    if (sentOff != null) {
      _removeExpulsedPlayersFromField(_effectiveSentOffPlayerIds());
    }

    if (needsDiscipline &&
        mounted &&
        !prevSentOff.contains(player.id) &&
        _sentOffPlayerIds.contains(player.id)) {
      unawaited(_showCardExpulsionSnack(player));
    }
  }

  /// Muestra un snack cuando un jugador es expulsado.
  /// Lo hace consultando el resumen de tarjetas y mostrando texto.
  Future<void> _showCardExpulsionSnack(Player player) async {
    try {
      final uc = context.read<GetPlayerCardSummaryForMatchPlayerUseCase>();
      final summaryResult = await uc(matchId: _match.id, playerId: player.id);

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

  /// Busca un jugador en la convocatoria por id.
  /// Lo hace recorriendo la lista local.
  Player? _playerFromRoster(int? id) {
    if (id == null) return null;
    for (final p in _convokedPlayers) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Normaliza notas de cambio de estado para mostrarlas.
  /// Lo hace traduciendo textos conocidos a l10n.
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

  /// Devuelve el texto para goles encajados.
  /// Lo hace aplicando fallback cuando la nota esta vacia.
  String _displayConcededGoalNote(String? note, AppLocalizations l10n) {
    if (note == null || note.isEmpty) return l10n.matchLiveConcededDefault;
    if (note == 'Gol del rival') return l10n.matchOpponentGoal;
    return note;
  }

  /// Indica si un statuschange representa un cambio de tiempo valido.
  /// Lo hace comprobando la nota contra frases conocidas.
  bool _isTimeChangeStatusEvent(Map<String, dynamic> row) {
    final key = _canonicalEventTypeKey(row['type']);
    if (key != 'statuschange') return false;
    final note = _dynToStr(row['note'])?.toLowerCase() ?? '';
    const allowed = {
      'inicio 1ª parte',
      'inicio 1a parte',
      'descanso',
      'inicio 2ª parte',
      'inicio 2a parte',
      'final del partido',
    };
    return allowed.contains(note);
  }

  /// Filtra eventos visibles para roles sin permisos de admin.
  /// Lo hace dejando solo tiempos, cambios, goles, faltas y tarjetas.
  List<Map<String, dynamic>> _filterLiveEventsForLimitedView(
    List<Map<String, dynamic>> events,
  ) {
    return events.where((row) {
      final key = _canonicalEventTypeKey(row['type']);
      if (key == 'statuschange') {
        return _isTimeChangeStatusEvent(row);
      }
      if (key == 'substitution') {
        return (_dynToInt(row['minute']) ?? 0) > 0;
      }
      return key == 'scoregoal' ||
          key == 'concedegoal' ||
          key == 'owngoal' ||
          key == 'foul' ||
          key == 'rivalfoul' ||
          key == 'yellowcard' ||
          key == 'redcard' ||
          key == 'rivalyellowcard' ||
          key == 'rivalredcard';
    }).toList();
  }

  /// Construye los spans de descripcion para un evento.
  /// Lo hace segun el tipo canonico y datos del evento.
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
          TextSpan(text: id != null ? l10n.matchUnknownPlayerId(id) : '—'),
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
        return [TextSpan(text: _displayConcededGoalNote(note, l10n))];
      case 'owngoal':
        return [TextSpan(text: l10n.matchLiveOwnGoal), ...dorsalSpans(p1)];
      case 'yellowcard':
        return [TextSpan(text: l10n.matchLiveYellowCard), ...dorsalSpans(p1)];
      case 'redcard':
        return [TextSpan(text: l10n.matchLiveRedCard), ...dorsalSpans(p1)];
      case 'rivalyellowcard':
        return [TextSpan(text: 'Tarjeta amarilla rival')];
      case 'rivalredcard':
        return [TextSpan(text: 'Tarjeta roja rival')];
      case 'goodsave':
        return [TextSpan(text: l10n.matchLiveGoodSave), ...dorsalSpans(p1)];
      case 'shot':
        return [TextSpan(text: l10n.matchLiveShot), ...dorsalSpans(p1)];
      case 'foul':
        return [TextSpan(text: l10n.matchLiveFoul), ...dorsalSpans(p1)];
      case 'offside':
        return [TextSpan(text: 'Fuera de juego'), ...dorsalSpans(p1)];
      case 'rivaloffside':
        return [TextSpan(text: 'Fuera de juego rival')];
      case 'cantada':
        return [TextSpan(text: l10n.matchLiveCantada), ...dorsalSpans(p1)];
      case 'keypass':
        return [TextSpan(text: l10n.matchLiveKeyPass), ...dorsalSpans(p1)];
      case 'goodpass':
        return [TextSpan(text: l10n.matchLiveGoodPass), ...dorsalSpans(p1)];
      case 'badpass':
        return [TextSpan(text: l10n.matchLiveBadPass), ...dorsalSpans(p1)];
      case 'goodplay':
        return [TextSpan(text: l10n.matchLiveGoodPlay), ...dorsalSpans(p1)];
      case 'badplay':
        return [TextSpan(text: l10n.matchLiveBadPlay), ...dorsalSpans(p1)];
      case 'ballrecovery':
        return [TextSpan(text: l10n.matchLiveBallRecovery), ...dorsalSpans(p1)];
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
        return [TextSpan(text: key.isEmpty ? l10n.matchLiveEvent : rawLabel)];
    }
  }

  /// Avatar de la fila de eventos: tarjetas con fondo amarillo/rojo acorde.
  /// Colores del avatar para cada evento en la lista.
  /// Lo hace aplicando reglas por tipo canonico.
  (Color background, Color iconColor) _liveEventListAvatarColors(
    ColorScheme scheme,
    String canonicalKey,
  ) {
    switch (canonicalKey) {
      case 'yellowcard':
      case 'rivalyellowcard':
        return (const Color(0xFFFFC107), Colors.black87);
      case 'redcard':
      case 'rivalredcard':
        return (scheme.error, scheme.onError);
      default:
        return (scheme.surfaceContainerHigh, scheme.primary);
    }
  }

  /// Devuelve el icono para un tipo de evento canonico.
  /// Lo hace con un switch por clave.
  IconData _iconForLiveEventKey(String canonicalKey) {
    switch (canonicalKey) {
      case 'scoregoal':
      case 'concedegoal':
      case 'owngoal':
        return Icons.sports_soccer;
      case 'yellowcard':
      case 'rivalyellowcard':
        return Icons.style;
      case 'redcard':
      case 'rivalredcard':
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
      case 'foul':
        return Icons.warning_amber_rounded;
      case 'offside':
      case 'rivaloffside':
        return Icons.outlined_flag;
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

  /// Gestiona el tap sobre un evento (borrado).
  /// Lo hace confirmando y luego eliminando en BD.
  Future<void> _onLiveEventTapped(Map<String, dynamic> row) async {
    if (_isExternal) {
      return;
    }
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack(
        AppLocalizations.of(context)!.matchLoginRequiredShort,
        error: true,
      );
      return;
    }

    final minute = _dynToInt(row['minute']) ?? 0;
    final half = _eventMatchHalf(row, _resolvedSecondHalfStart());
    final minutePrefix = minute != 0
        ? '${_formatLiveEventMinuteLine(minute, half)} · '
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
        _showSnack(
          AppLocalizations.of(context)!.matchEventDeleteFail,
          error: true,
        );
      }
    }
  }

  /// Carga la ultima formacion registrada en eventos.
  /// Lo hace leyendo la nota de formacion mas reciente.
  Future<void> _loadLastFormationFromEvents() async {
    try {
      final uc = context.read<GetLatestFormationNoteByMatchUseCase>();
      final result = await uc(_match.id);
      await result.fold<Future<void>>((_) async {}, (formationNote) async {
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
      });
    } catch (_) {
      // Si falla, mantenemos la formación actual
    }
  }

  /// Muestra un dialogo de confirmacion generico.
  /// Lo hace devolviendo true cuando el usuario confirma.
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

  /// Muestra un snackbar simple.
  /// Lo hace usando ScaffoldMessenger.
  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Muestra un snackbar con texto enriquecido.
  /// Lo hace construyendo un TextSpan con estilos.
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

  /// Actualiza en BD los titulares actuales del partido.
  /// Lo hace enviando la lista de ids titulares.
  Future<void> _updateStartersInMatchLineup() async {
    try {
      final starterIds = _positionPlayers
          .where((p) => p != null)
          .map((p) => p!.id)
          .toSet()
          .toList();

      if (starterIds.isEmpty) return;

      final uc = context.read<ApplyMatchLineupStartersUseCase>();
      await uc(matchId: _match.id, starterPlayerIds: starterIds);
    } catch (e) {
      // No rompemos la UI si falla; solo registramos el error.
      debugPrint('Error updating starters in match_lineup: $e');
    }
  }

  /// Guarda un evento de formacion con la clave seleccionada.
  /// Lo hace creando un MatchEvent y guardandolo.
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

  /// Guarda un evento de sustitucion con nota de entrada/salida.
  /// Lo hace creando el evento y persistiendo en BD.
  Future<void> _saveSubstitutionEvent({
    required Player playerIn,
    Player? playerOut,
    bool refreshLiveEventsAfterSave = true,
  }) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        return;
      }

      final saveMatchEventUseCase = context.read<SaveMatchEventUseCase>();
      final minute = _currentMatchMinute();
      final l10n = AppLocalizations.of(context)!;

      // No se permite registrar una sustitución donde el jugador que sale
      // ya ha sido expulsado: la expulsión implica que no puede volver.
      if (playerOut != null && _sentOffPlayerIds.contains(playerOut.id)) {
        _showSnack(l10n.matchPlayerSentOffCannotReturn, error: true);
        return;
      }

      final inNumber = playerIn.number?.toString() ?? '-';
      final outNumber = playerOut?.number?.toString() ?? '-';
      final String note;
      if (_phase == _MatchPhase.halfTime) {
        // En el descanso, marcamos la sustitución como "halftime" en la nota.
        note = 'In:$inNumber,out:$outNumber,halftime';
      } else {
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

      await saveMatchEventUseCase(event, authState.user, widget.team.id);
      if (refreshLiveEventsAfterSave && mounted) {
        await _loadLiveEvents();
      }
    } catch (e) {
      debugPrint('Error saving substitution event: $e');
    }
  }

  Future<void> _commitLineupChangeSideEffects({
    required bool logSubstitutionEvent,
    Player? substitutionIn,
    Player? substitutionOut,
  }) async {
    _saveCurrentLineup();
    await _persistCurrentPositionsToMatchLineup();

    if (logSubstitutionEvent && substitutionIn != null) {
      await _saveSubstitutionEvent(
        playerIn: substitutionIn,
        playerOut: substitutionOut,
        refreshLiveEventsAfterSave: false,
      );
    }
  }

  /// Maneja el registro manual de gol del rival.
  /// Lo hace pidiendo confirmacion y guardando el evento.
  Future<void> _onAddGoal({required bool ourTeam}) async {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack(l10n.matchMustLoginRegisterGoals, error: true);
      return;
    }

    final confirmed = await _confirmAction(
      l10n.matchConfirmGoalTitle,
      ourTeam ? l10n.matchConfirmAddGoalOur : l10n.matchConfirmAddGoalRival,
    );
    if (!confirmed) return;

    try {
      if (ourTeam) {
        _showSnack(l10n.matchGoalsOurTeamFromField, error: true);
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

  /// Carga jugadores convocados y datos dependientes.
  /// Lo hace leyendo ids de match_lineup y luego la plantilla.
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

          final starterById = <int, bool>{
            for (final l in _match.lineups) l.playerId: l.isStarting,
          };
          convoked.sort((a, b) {
            final aStarter = starterById[a.id] ?? false;
            final bStarter = starterById[b.id] ?? false;
            if (aStarter != bStarter) {
              return aStarter ? -1 : 1;
            }
            return (a.number ?? 0).compareTo(b.number ?? 0);
          });

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

  /// Carga posiciones desde match_lineup y actualiza el campo.
  /// Lo hace mapeando ids a jugadores convocados.
  Future<void> _loadPositionsFromEvents() async {
    try {
      final uc = context.read<FetchMatchLineupPositionsUseCase>();
      final res = await uc(_match.id);

      if (!mounted) return;

      await res.fold<Future<void>>((_) async {}, (assignments) async {
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
      });
    } catch (e) {
      debugPrint('Error loading positions from match_lineup: $e');
    }
  }

  /// Carga expulsados y refresca el estado local.
  /// Lo hace consultando ids y sincronizando el estado interno.
  Future<void> _loadDisciplineStateFromEvents() async {
    final sentOff = await _querySentOffIdsFromEvents();
    if (sentOff == null || !mounted) return;
    final effective = <int>{...sentOff, ..._deriveSentOffFromLiveEvents()};

    // Registrar minutos de expulsión detectados en los eventos ya cargados.
    _recordExpulsionMinutesFromRows(_liveEvents);

    setState(() {
      _sentOffPlayerIds
        ..clear()
        ..addAll(effective);

      if (_selectedPlayer != null &&
          _sentOffPlayerIds.contains(_selectedPlayer!.id)) {
        _selectedPlayer = null;
      }
    });
    // Quitar automáticamente del campo a los expulsados.
    _removeExpulsedPlayersFromField(effective);
  }

  /// Texto del boton principal segun la fase del partido.
  /// Lo hace con un switch sobre [_MatchPhase].
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

  /// Texto visible de la fase actual del partido.
  /// Lo hace considerando estado final y fase interna.
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

  /// Abre el modal de acciones del jugador y confirma registro.
  /// Lo hace mostrando dialogos y guardando el evento.
  Future<void> _onPlayerActionRequested(Player player) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isExternal) {
      _showSnack(l10n.matchSpectatorNoPlayerActions, error: true);
      return;
    }
    final action = await showMatchPlayerActionModal(context, player);

    if (action == null) return;

    final label = _playerActionLabel(action, l10n);
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

    await _savePlayerActionEvent(player, action);
  }

  /// Devuelve la etiqueta localizada de una accion.
  /// Lo hace con un switch sobre [MatchPlayerActionType].
  String _playerActionLabel(
    MatchPlayerActionType action,
    AppLocalizations l10n,
  ) {
    switch (action) {
      case MatchPlayerActionType.goal:
        return l10n.matchActionLabelGoal;
      case MatchPlayerActionType.goodPass:
        return l10n.matchActionLabelGoodPass;
      case MatchPlayerActionType.goodPlay:
        return l10n.matchActionLabelGoodPlay;
      case MatchPlayerActionType.goodSave:
        return l10n.matchActionLabelGoodSave;
      case MatchPlayerActionType.ballRecovery:
        return l10n.matchActionLabelBallRecovery;
      case MatchPlayerActionType.shot:
        return l10n.matchActionLabelShot;
      case MatchPlayerActionType.yellowCard:
        return l10n.matchActionLabelYellowCard;
      case MatchPlayerActionType.redCard:
        return l10n.matchActionLabelRedCard;
      case MatchPlayerActionType.badPass:
        return l10n.matchActionLabelBadPass;
      case MatchPlayerActionType.badPlay:
        return l10n.matchActionLabelBadPlay;
      case MatchPlayerActionType.foul:
        return l10n.matchActionLabelFoul;
      case MatchPlayerActionType.offside:
        return 'Fuera de juego';
      case MatchPlayerActionType.cantada:
        return l10n.matchActionLabelCantada;
    }
  }

  /// Guarda la accion seleccionada como evento del partido.
  /// Lo hace creando el MatchEvent y refrescando derivados.
  Future<void> _savePlayerActionEvent(
    Player player,
    MatchPlayerActionType action,
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

      // Caso especial: gol con posible asistente y gol de equipo
      if (action == MatchPlayerActionType.goal) {
        await _savePlayerGoalWithAssist(
          player: player,
          minute: minute,
          authUser: authState.user,
          saveMatchEventUseCase: saveMatchEventUseCase,
        );
        return;
      }

      late MatchEventEnum type;
      late String note;

      switch (action) {
        case MatchPlayerActionType.goal:
          // El caso de gol se maneja antes con _savePlayerGoalWithAssist.
          return;
        case MatchPlayerActionType.goodPass:
          type = MatchEventEnum.goodPass;
          note = 'Buen pase';
          break;
        case MatchPlayerActionType.goodPlay:
          type = MatchEventEnum.goodPlay;
          note = 'Buena jugada';
          break;
        case MatchPlayerActionType.goodSave:
          type = MatchEventEnum.goodSave;
          note = 'Buena parada';
          break;
        case MatchPlayerActionType.ballRecovery:
          type = MatchEventEnum.ballRecovery;
          note = 'Balón recuperado';
          break;
        case MatchPlayerActionType.shot:
          type = MatchEventEnum.shot;
          note = 'Tiro';
          break;
        case MatchPlayerActionType.badPass:
          type = MatchEventEnum.badPass;
          note = 'Mal pase';
          break;
        case MatchPlayerActionType.badPlay:
          type = MatchEventEnum.badPlay;
          note = 'Mala jugada';
          break;
        case MatchPlayerActionType.foul:
          type = MatchEventEnum.foul;
          note = 'Falta';
          break;
        case MatchPlayerActionType.offside:
          type = MatchEventEnum.offside;
          note = 'Fuera de juego';
          break;
        case MatchPlayerActionType.yellowCard:
          type = MatchEventEnum.yellowCard;
          note = 'Tarjeta amarilla';
          break;
        case MatchPlayerActionType.redCard:
          type = MatchEventEnum.redCard;
          note = 'Tarjeta roja';
          break;
        case MatchPlayerActionType.cantada:
          type = MatchEventEnum.cantada;
          note = 'Cantada';
          break;
      }

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

  /// Permite elegir asistente entre jugadores en campo.
  /// Lo hace mostrando un dialogo con la lista filtrada.
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

  /// Guarda un gol con posible asistente en un solo evento.
  /// Lo hace pidiendo asistente y persistiendo el MatchEvent.
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
          _applyOptimisticScoreChange(goalsScoredDelta: 1);
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
          _applyOptimisticScoreChange(goalsConcededDelta: 1);
        },
      );
    } catch (e) {
      _showSnack(l10n.matchGoalSaveFail, error: true);
    }
  }

  /// Accion principal segun fase (iniciar, descanso, reanudar, finalizar).
  /// Lo hace validando, confirmando y llamando a casos de uso.
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
            SnackBar(
              content: Text(l10n.matchStartedOk),
              backgroundColor: Colors.green,
            ),
          );
          _matchStartTimes[_match.id] = startTime;
          _saveCurrentLineup();
          // Persistimos la posición actual de cada jugador en match_lineup.position
          _persistCurrentPositionsToMatchLineup();
          // Actualizamos en BD qué jugadores empiezan como titulares.
          _updateStartersInMatchLineup();
          // Guardamos evento de inicio de partido / 1ª parte
          _saveStatusChangeEvent(MatchStatus.firstHalf, 0);
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
            _elapsedSeconds = 0;
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
      // Pasar a descanso: paramos el cronómetro y cambiamos de fase
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
          htRes.fold((failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }, (_) {});
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
        _elapsedSeconds = 0;
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
          shRes.fold((failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }, (_) {});
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
      // Terminar partido
      _isTimerRunning = false;
      _timer?.cancel();

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

      // Asegura en BD la disposición actual del campo para el detalle del partido.
      await _persistCurrentPositionsToMatchLineup();

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
          final getLatestFormationNoteByMatchUseCase = context
              .read<GetLatestFormationNoteByMatchUseCase>();
          final loadErrorMessage = AppLocalizations.of(
            context,
          )!.matchStatsLoadError;
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (ctx) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<TeamContextCubit>()),
                  BlocProvider(
                    create: (_) => MatchStatsCubit(
                      match: finishedMatch,
                      getPlayersByTeamUseCase: getPlayersByTeamUseCase,
                      getMatchEventsByMatchUseCase:
                          getMatchEventsByMatchUseCase,
                      getMatchLineupsByMatchUseCase:
                          getMatchLineupsByMatchUseCase,
                      getLatestFormationNoteByMatchUseCase:
                          getLatestFormationNoteByMatchUseCase,
                      loadErrorMessage: loadErrorMessage,
                    )..load(),
                  ),
                ],
                child: MatchStatsPage(
                  match: finishedMatch,
                  ourTeamName: context.read<TeamContextCubit>().state.name,
                ),
              ),
            ),
          );
        },
      );
    }
  }

  /// Construye la pantalla completa del gestor de partido.
  /// Lo hace componiendo tarjetas, lista y campo con estado actual.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isExternal = _isExternal;
    final bool canSeeAllEvents = _canSeeAllEvents;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final s = context.layoutScale;
    final pagePad = AppResponsive.pageHorizontalPadding(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final yellowCardPlayerIds = <int>{
      for (final row in _liveEvents)
        if (_canonicalEventTypeKey(row['type']) == 'yellowcard')
          _dynToInt(row['player_id1']) ?? -1,
    }..remove(-1);
    final effectiveSentOff = _effectiveSentOffPlayerIds();
    int countByKey(String key) {
      var total = 0;
      for (final row in _liveEvents) {
        if (_canonicalEventTypeKey(row['type']) == key) {
          total++;
        }
      }
      return total;
    }

    final offsidesOur = countByKey('offside');
    final offsidesRival = countByKey('rivaloffside');
    final yellowCardsOur = countByKey('yellowcard');
    final yellowCardsRival = countByKey('rivalyellowcard');
    final redCardsOur = countByKey('redcard');
    final redCardsRival = countByKey('rivalredcard');
    final visibleLiveEvents = canSeeAllEvents
        ? _liveEvents
        : _filterLiveEventsForLimitedView(_liveEvents);
    final showLastEvent =
        _showLiveLastEventHighlight && visibleLiveEvents.isNotEmpty;
    final lastEvent = showLastEvent ? visibleLiveEvents.first : null;
    final eventsHint = canSeeAllEvents
        ? l10n.matchEventsHintCoach
        : l10n.matchEventsHintSpectator;

    // Widget del cronometro principal y el descuento.
    Widget clockWidget() {
      final mainSeconds = _mainClockSeconds();
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

    final principalList = ListView(
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${_match.goalsScored}',
                                  style: theme.textTheme.displaySmall?.copyWith(
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
                                  style: theme.textTheme.displaySmall?.copyWith(
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
                    Center(child: clockWidget()),
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
                              icon: Icon(Icons.grid_view_rounded, size: 18 * s),
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
                      child: MatchFieldWithFormation(
                        formationLines: _formationLines,
                        formationLayoutKey: _selectedFormation,
                        positionPlayers: _positionPlayers,
                        selectedPlayer: _selectedPlayer,
                        sentOffPlayerIds: effectiveSentOff,
                        currentPlayersOnField: _currentPlayersOnField,
                        maxPlayersOnField: _maxPlayersOnField,
                        showSnack: _showSnack,
                        onLineupChanged:
                            (
                              newPositions, {
                              required logSubstitutionEvent,
                              substitutionIn,
                              substitutionOut,
                            }) {
                              setState(() {
                                _positionPlayers = newPositions;
                                _selectedPlayer = null;
                                _lastLocalLineupChangeAt = DateTime.now();
                              });
                              unawaited(
                                _commitLineupChangeSideEffects(
                                  logSubstitutionEvent: logSubstitutionEvent,
                                  substitutionIn: substitutionIn,
                                  substitutionOut: substitutionOut,
                                ),
                              );
                            },
                        onPlayerActionRequested: _onPlayerActionRequested,
                        readOnly: isExternal,
                        playerDiscipline: (playerId) {
                          if (effectiveSentOff.contains(playerId)) {
                            return MatchPlayerDisciplineHighlight.red;
                          }
                          if (yellowCardPlayerIds.contains(playerId)) {
                            return MatchPlayerDisciplineHighlight.yellow;
                          }
                          return MatchPlayerDisciplineHighlight.none;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showLastEvent && lastEvent != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildLiveLastEventBlinkBanner(
              theme,
              scheme,
              isExternal,
              l10n,
              lastEvent,
            ),
          ),
        ],
        const SizedBox(height: 12),
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
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
                  sentOffPlayerIds: effectiveSentOff,
                  yellowCardPlayerIds: yellowCardPlayerIds,
                  playerRatings: _playerRatings,
                  minutesPlayedByPlayerId: _canSeeConvokedMinutesPlayed
                      ? _computeMinutesPlayedForConvoked()
                      : null,
                  scrollingChild: true,
                  readOnly: isExternal,
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
      ],
    );

    final statsList = ListView(
      padding: EdgeInsets.fromLTRB(pagePad, 12 * s, pagePad, 24 * s),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
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
            offsidesOur: offsidesOur,
            offsidesRival: offsidesRival,
            yellowOur: yellowCardsOur,
            yellowRival: yellowCardsRival,
            redOur: redCardsOur,
            redRival: redCardsRival,
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
            onRemoveRivalOffside: isExternal
                ? null
                : () => _removeLastOfType(MatchEventEnum.rivalOffside),
            onAddRivalOffside: isExternal
                ? null
                : () => _saveManualCounterEvent(
                    type: MatchEventEnum.rivalOffside,
                    note: 'Fuera de juego rival',
                  ),
            onRemoveRivalYellowCard: isExternal
                ? null
                : () => _removeLastOfType(MatchEventEnum.rivalYellowCard),
            onAddRivalYellowCard: isExternal
                ? null
                : () => _saveManualCounterEvent(
                    type: MatchEventEnum.rivalYellowCard,
                    note: 'Tarjeta amarilla rival',
                  ),
            onRemoveRivalRedCard: isExternal
                ? null
                : () => _removeLastOfType(MatchEventEnum.rivalRedCard),
            onAddRivalRedCard: isExternal
                ? null
                : () => _saveManualCounterEvent(
                    type: MatchEventEnum.rivalRedCard,
                    note: 'Tarjeta roja rival',
                  ),
          ),
        ),
      ],
    );

    final eventsList = ListView(
      padding: EdgeInsets.fromLTRB(pagePad, 12 * s, pagePad, 24 * s),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Card(
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
                  eventsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                if (visibleLiveEvents.isEmpty)
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
                  for (int i = 0; i < visibleLiveEvents.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isExternal
                            ? null
                            : () => _onLiveEventTapped(visibleLiveEvents[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              () {
                                final evKey = _canonicalEventTypeKey(
                                  visibleLiveEvents[i]['type'],
                                );
                                final avatar = _liveEventListAvatarColors(
                                  scheme,
                                  evKey,
                                );
                                return CircleAvatar(
                                  radius: 18,
                                  backgroundColor: avatar.$1,
                                  child: Icon(
                                    _iconForLiveEventKey(evKey),
                                    size: 18,
                                    color: avatar.$2,
                                  ),
                                );
                              }(),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        children: _liveEventDescriptionSpans(
                                          l10n,
                                          visibleLiveEvents[i],
                                          theme.textTheme.bodyMedium!.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      softWrap: true,
                                    ),
                                    Text(
                                      () {
                                        final m =
                                            _dynToInt(
                                              visibleLiveEvents[i]['minute'],
                                            ) ??
                                            0;
                                        final half = _eventMatchHalf(
                                          visibleLiveEvents[i],
                                          _resolvedSecondHalfStart(),
                                        );
                                        return _formatLiveEventMinuteLine(
                                          m,
                                          half,
                                        );
                                      }(),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
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
                  ],
              ],
            ),
          ),
        ),
      ],
    );

    return TeamBrandedScope(
      team: widget.team,
      child: DefaultTabController(
        length: 3,
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
            child: Column(
              children: [
                Material(
                  color: scheme.surface,
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'Principal'),
                      Tab(text: 'Estadisticas'),
                      Tab(text: 'Eventos'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: _onRefreshMatchScreen,
                        child: principalList,
                      ),
                      RefreshIndicator(
                        onRefresh: _onRefreshMatchScreen,
                        child: statsList,
                      ),
                      RefreshIndicator(
                        onRefresh: _onRefreshMatchScreen,
                        child: eventsList,
                      ),
                    ],
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
