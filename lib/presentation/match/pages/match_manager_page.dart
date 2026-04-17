import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/domain/entities/enum/match_status.dart';
import 'package:football_manager/domain/entities/enum/match_event_enum.dart';
import 'package:football_manager/domain/entities/auth_user.dart' as tfg_auth;
import 'package:football_manager/domain/entities/match.dart';
import 'package:football_manager/domain/entities/match_event.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/entities/enum/user_role.dart';
import 'package:football_manager/domain/usecase/match/finish_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/start_match_use_case.dart';
import 'package:football_manager/domain/usecase/match/get_match_lineups_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_latest_formation_note_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/get_match_events_by_match_use_case.dart';
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/save_match_event_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/delete_match_event_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_convocation_table.dart';
import 'package:football_manager/presentation/match/widgets/match_field_with_formation.dart';
import 'package:football_manager/presentation/match/widgets/match_player_action_modal.dart';
import 'package:football_manager/presentation/match/pages/match_stats_page.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
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
    with SingleTickerProviderStateMixin {
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

  RealtimeChannel? _spectatorMatchRealtimeChannel;
  Timer? _spectatorRealtimeDebounce;

  late AnimationController _lastEventBlinkController;

  bool get _isExternal {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return false;
    return authState.user.teamRoles[widget.team.id] == UserRole.external;
  }

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _lastEventBlinkController.dispose();
    _timer?.cancel();
    _spectatorRealtimeDebounce?.cancel();
    final ch = _spectatorMatchRealtimeChannel;
    _spectatorMatchRealtimeChannel = null;
    if (ch != null) {
      unawaited(Supabase.instance.client.removeChannel(ch));
    }
    super.dispose();
  }

  void _startTimer() {
    _isTimerRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isTimerRunning || !mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

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
  void _subscribeSpectatorRealtime() {
    if (!_isExternal) return;
    if (_spectatorMatchRealtimeChannel != null) return;
    if (_match.status == MatchStatus.finished) return;

    final mid = _match.id;
    void onRemoteChange() {
      if (!mounted) return;
      _scheduleSpectatorRealtimeRefresh();
    }

    _spectatorMatchRealtimeChannel = Supabase.instance.client
        .channel('match_spectator_$mid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: mid,
          ),
          callback: (_) => onRemoteChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_lineup',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: mid,
          ),
          callback: (_) => onRemoteChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: mid,
          ),
          callback: (_) => onRemoteChange(),
        )
        .subscribe();
  }

  void _scheduleSpectatorRealtimeRefresh() {
    _spectatorRealtimeDebounce?.cancel();
    _spectatorRealtimeDebounce = Timer(const Duration(milliseconds: 400), () {
      _spectatorRealtimeDebounce = null;
      if (!mounted) return;
      unawaited(_onRefreshMatchScreen());
    });
  }

  MatchStatus? _parseMatchStatusColumn(dynamic raw) {
    if (raw == null) return null;
    final tail = raw.toString().split('.').last;
    for (final v in MatchStatus.values) {
      if (v.toString().split('.').last == tail) {
        return v;
      }
    }
    return null;
  }

  Future<void> _syncMatchMetaFromServer() async {
    try {
      final row = await Supabase.instance.client
          .from('matches')
          .select('status')
          .eq('id', _match.id)
          .maybeSingle();
      if (!mounted || row == null) return;
      final status = _parseMatchStatusColumn(row['status']);
      if (status == null || status == _match.status) return;

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

      if (status == MatchStatus.firstHalf || status == MatchStatus.secondHalf) {
        if (mounted && !_isTimerRunning) {
          _initializeTimer();
        }
      }
    } catch (e) {
      debugPrint('Error syncing match meta: $e');
    }
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
      // Categorías pequeñas (fútbol 7): mantenemos las formaciones actuales.
      _formationOptions = {
        '3-2-1': [3, 2, 1],
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
    final now = DateTime.now();
    final startTime = _matchStartTimes[_match.id] ?? _match.date;
    final diff = now.difference(startTime).inSeconds;
    _elapsedSeconds = diff > 0 ? diff : 0;
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

  void _saveCurrentLineup() {
    final playerIds = _positionPlayers.map((p) => p?.id).toList();
    _savedLineups[_match.id] = _SavedLineupState(
      formationKey: _selectedFormation,
      playerIds: playerIds,
    );
  }

  Future<void> _persistCurrentPositionsToMatchLineup() async {
    try {
      final supabase = Supabase.instance.client;

      final Map<int, int> positionByPlayerId = {};
      for (int i = 0; i < _positionPlayers.length; i++) {
        final player = _positionPlayers[i];
        if (player != null) {
          positionByPlayerId[player.id] = i;
        }
      }

      for (final player in _convokedPlayers) {
        final int? pos = positionByPlayerId[player.id];
        await supabase
            .from('match_lineup')
            .update({'position': pos})
            .eq('match_id', _match.id)
            .eq('player_id', player.id);
      }
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

  int _currentMatchMinute() {
    final baseMinutes = _elapsedSeconds ~/ 60;
    if (_phase == _MatchPhase.secondHalf) {
      // Sumamos la duración de la 1ª parte según categoría
      return baseMinutes + _firstHalfDurationMinutesForCategory();
    }
    return baseMinutes;
  }

  int _halfDurationSeconds() => _firstHalfDurationMinutesForCategory() * 60;

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

  Future<({int scored, int conceded})?> _queryScoreCountsFromEvents() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('match_events')
          .select('type')
          .eq('match_id', _match.id);

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

      return (scored: scored, conceded: conceded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _reloadScoreFromEvents() async {
    final counts = await _queryScoreCountsFromEvents();
    if (counts == null || !mounted) return;
    setState(() {
      _match = Match(
        id: _match.id,
        teamId: _match.teamId,
        opponent: _match.opponent,
        goalsScored: counts.scored,
        goalsConceded: counts.conceded,
        date: _match.date,
        hour: _match.hour,
        status: _match.status,
        lineups: _match.lineups,
        isHome: _match.isHome,
      );
    });
  }

  Future<Map<int, double>?> _queryPlayerRatingsMap() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('match_events')
          .select('type, player_id1, player_id2, note')
          .eq('match_id', _match.id);

      final events = List<Map<String, dynamic>>.from(result as List);

      final Map<int, double> newRatings = {};
      for (final player in _convokedPlayers) {
        newRatings[player.id] = calculatePlayerRating(player.id, events);
      }
      return newRatings;
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
  Future<void> _onRefreshMatchScreen() async {
    await _reloadScoreFromEvents();
    if (!mounted) return;
    await _recalculatePlayerRatings();
    if (!mounted) return;
    await _loadLiveEvents();
    if (!mounted) return;
    await _loadLastFormationFromEvents();
    if (!mounted) return;
    await _loadPositionsFromEvents();
    if (!mounted) return;
    await _loadDisciplineStateFromEvents();
    if (!mounted) return;
    if (_isExternal) {
      await _syncMatchMetaFromServer();
    }
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

  /// Notas de [statusChange] que marcan el reloj del partido (alineado con estadísticas).
  bool _isMatchTimeStatusNote(String? note) {
    if (note == null || note.isEmpty) return false;
    final lower = note.trim().toLowerCase();
    const allowed = [
      'inicio 1ª parte',
      'inicio 1a parte',
      'descanso',
      'inicio 2ª parte',
      'inicio 2a parte',
      'final del partido',
    ];
    return allowed.any((n) => lower == n.toLowerCase());
  }

  /// Lista de eventos en vivo: solo goles, cambios de tiempo y cambios de jugador.
  /// Pases, jugadas, recuperaciones, tarjetas, etc. siguen guardados pero no se listan aquí.
  bool _shouldIncludeInLiveEventsList(Map<String, dynamic> row) {
    final key = _canonicalEventTypeKey(row['type']);
    if (key == 'formation') {
      return false;
    }
    if (key == 'substitution') {
      return _dynToInt(row['player_id2']) != null;
    }
    if (key == 'scoregoal' || key == 'concedegoal' || key == 'owngoal') {
      return true;
    }
    if (key == 'statuschange') {
      return _isMatchTimeStatusNote(_dynToStr(row['note']));
    }
    return false;
  }

  DateTime _parseEventCreatedAt(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
  }

  /// Nota del evento [statusChange] al pasar a la 2ª parte (ver [_saveStatusChangeEvent]).
  bool _noteIndicatesSecondHalfKickoff(String? note) {
    if (note == null || note.isEmpty) return false;
    final n = note.toLowerCase();
    return n.contains('inicio') && n.contains('2') && n.contains('parte');
  }

  /// Momento del último "Inicio 2ª parte" en la lista ya filtrada (por si hubiera duplicados).
  DateTime? _resolveSecondHalfStartFromRows(List<Map<String, dynamic>> rows) {
    DateTime? best;
    for (final r in rows) {
      if (_canonicalEventTypeKey(r['type']) != 'statuschange') continue;
      final note = _dynToStr(r['note']);
      if (!_noteIndicatesSecondHalfKickoff(note)) continue;
      final t = _parseEventCreatedAt(r['created_at']);
      if (best == null || t.isAfter(best)) {
        best = t;
      }
    }
    return best;
  }

  /// 1 = primera parte, 2 = segunda. Sin ancla de inicio 2ª: todo se trata como 1ª.
  int _eventMatchHalf(Map<String, dynamic> row, DateTime? secondHalfStart) {
    if (secondHalfStart == null) return 1;
    final t = _parseEventCreatedAt(row['created_at']);
    return !t.isBefore(secondHalfStart) ? 2 : 1;
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

  DateTime? _resolvedSecondHalfStart() =>
      _resolveSecondHalfStartFromRows(_liveEvents);

  /// 2ª parte arriba, 1ª abajo. En cada parte: de abajo a arriba de menos a más
  /// minuto (en la columna, más minutos arriba; mismo minuto, más reciente arriba).
  int _compareLiveEventsDisplayOrder(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    DateTime? secondHalfStart,
  ) {
    final ha = _eventMatchHalf(a, secondHalfStart);
    final hb = _eventMatchHalf(b, secondHalfStart);
    if (ha != hb) {
      return hb.compareTo(ha);
    }
    final ma = _dynToInt(a['minute']) ?? 0;
    final mb = _dynToInt(b['minute']) ?? 0;
    if (ma != mb) {
      return mb.compareTo(ma);
    }
    final ca = _parseEventCreatedAt(a['created_at']);
    final cb = _parseEventCreatedAt(b['created_at']);
    final byTime = cb.compareTo(ca);
    if (byTime != 0) {
      return byTime;
    }
    final ida = _dynToInt(a['id']) ?? 0;
    final idb = _dynToInt(b['id']) ?? 0;
    return idb.compareTo(ida);
  }

  Future<List<Map<String, dynamic>>?> _queryLiveEventsFiltered() async {
    try {
      final supabase = Supabase.instance.client;
      final raw = await supabase
          .from('match_events')
          .select(
            'id, match_id, type, minute, player_id1, player_id2, note, created_at',
          )
          .eq('match_id', _match.id)
          .order('minute', ascending: true)
          .order('created_at', ascending: true);

      final list = raw as List;
      final out = list
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            m['minute'] = resolveMatchEventMinute(m);
            final id1 = supabaseInt(m['player_id1']);
            final id2 = supabaseInt(m['player_id2']);
            if (id1 != null) m['player_id1'] = id1;
            if (id2 != null) m['player_id2'] = id2;
            return m;
          })
          .where(_shouldIncludeInLiveEventsList)
          .toList();
      final t2h = _resolveSecondHalfStartFromRows(out);
      out.sort((a, b) => _compareLiveEventsDisplayOrder(a, b, t2h));
      return out;
    } catch (e) {
      debugPrint('Error loading live events: $e');
      return null;
    }
  }

  Future<Set<int>?> _querySentOffIdsFromEvents() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('match_events')
          .select('type, player_id1')
          .eq('match_id', _match.id);

      final Map<int, int> yellowCounts = {};
      final Set<int> sentOff = {};

      for (final row in result) {
        final raw = row['type'];
        if (raw == null) continue;
        final typeString = raw.toString().split('.').last;
        final p1 = _dynToInt(row['player_id1']);
        if (p1 == null) continue;

        if (typeString == 'redCard') {
          sentOff.add(p1);
        } else if (typeString == 'yellowCard') {
          final current = yellowCounts[p1] ?? 0;
          final next = current + 1;
          yellowCounts[p1] = next;
          if (next >= 2) {
            sentOff.add(p1);
          }
        }
      }
      return sentOff;
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
    final needsDiscipline =
        type == MatchEventEnum.yellowCard || type == MatchEventEnum.redCard;

    final prevSentOff = Set<int>.from(_sentOffPlayerIds);

    final fRatings = _queryPlayerRatingsMap();
    final fLive = _queryLiveEventsFiltered();
    final Future<({int scored, int conceded})?>? fScore = needsScore
        ? _queryScoreCountsFromEvents()
        : null;
    final Future<Set<int>?>? fDisc = needsDiscipline
        ? _querySentOffIdsFromEvents()
        : null;

    final ratings = await fRatings;
    final live = await fLive;
    final score = fScore != null ? await fScore : null;
    final sentOff = fDisc != null ? await fDisc : null;

    if (!mounted) return;
    if (ratings == null || live == null) {
      await _refreshDerivedMatchData();
      return;
    }
    if (needsScore && score == null) {
      await _refreshDerivedMatchData();
      return;
    }
    if (needsDiscipline && sentOff == null) {
      await _refreshDerivedMatchData();
      return;
    }

    setState(() {
      if (score != null) {
        _match = Match(
          id: _match.id,
          teamId: _match.teamId,
          opponent: _match.opponent,
          goalsScored: score.scored,
          goalsConceded: score.conceded,
          date: _match.date,
          hour: _match.hour,
          status: _match.status,
          lineups: _match.lineups,
          isHome: _match.isHome,
        );
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

    if (needsDiscipline &&
        mounted &&
        !prevSentOff.contains(player.id) &&
        _sentOffPlayerIds.contains(player.id)) {
      unawaited(_showCardExpulsionSnack(player));
    }
  }

  Future<void> _showCardExpulsionSnack(Player player) async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('match_events')
          .select('type, player_id1')
          .eq('match_id', _match.id)
          .eq('player_id1', player.id);

      int yellowCount = 0;
      bool hasRed = false;

      for (final row in result) {
        final raw = row['type'];
        if (raw == null) continue;
        final typeString = raw.toString().split('.').last;
        if (typeString == 'yellowCard') {
          yellowCount++;
        } else if (typeString == 'redCard') {
          hasRed = true;
        }
      }

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
        if (note != null && note.isNotEmpty) {
          if (p1 != null) {
            return [
              TextSpan(text: l10n.matchLiveSaveBy),
              ...dorsalSpans(p1),
              TextSpan(text: ' · $note'),
            ];
          }
          return [TextSpan(text: l10n.matchLiveSaveWithNote(note))];
        }
        if (p1 != null) {
          return [
            TextSpan(text: l10n.matchLiveSaveBy),
            ...dorsalSpans(p1),
          ];
        }
        return [TextSpan(text: l10n.matchLiveSaveOnly)];
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
        _showSnack(AppLocalizations.of(context)!.matchEventDeleteFail, error: true);
      }
    }
  }

  Future<void> _loadLastFormationFromEvents() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('match_events')
          .select('id, type, note, minute')
          .eq('match_id', _match.id)
          .eq('type', 'formation')
          // Usamos el id descendente para asegurar que obtenemos
          // siempre la última formación guardada, incluso si varias
          // tienen el mismo minuto (0 antes de empezar el partido).
          .order('id', ascending: false)
          .limit(1);

      if (result.isEmpty) return;

      final row = result.first;
      final formation = (row['note'] as String?)?.trim();
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
        duration: error
            ? const Duration(seconds: 4)
            : const Duration(seconds: 1),
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
        duration: error
            ? const Duration(seconds: 4)
            : const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _updateStartersInMatchLineup() async {
    try {
      final supabase = Supabase.instance.client;

      // Primero marcamos a todos los convocados de este partido como no titulares.
      await supabase
          .from('match_lineup')
          .update({'is_start': false})
          .eq('match_id', _match.id);

      // Luego marcamos como titulares a los jugadores que están en el campo
      // cuando se inicia el partido.
      final starterIds = _positionPlayers
          .where((p) => p != null)
          .map((p) => p!.id)
          .toSet()
          .toList();

      if (starterIds.isEmpty) return;
      // En esta versión del cliente Postgrest no está disponible in_,
      // así que actualizamos uno a uno.
      for (final playerId in starterIds) {
        await supabase
            .from('match_lineup')
            .update({'is_start': true})
            .eq('match_id', _match.id)
            .eq('player_id', playerId);
      }
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
      final minute = _currentMatchMinute();

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
      if (mounted) await _loadLiveEvents();
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
      // Solo permitimos registrar goles del rival desde este botón.
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

  Future<void> _onRemoveGoal({required bool ourTeam}) async {
    final l10n = AppLocalizations.of(context)!;
    final currentGoals = ourTeam ? _match.goalsScored : _match.goalsConceded;
    if (currentGoals <= 0) {
      _showSnack(l10n.matchNoGoalsToRemove, error: true);
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack(l10n.matchMustLoginRemoveGoals, error: true);
      return;
    }

    final confirmed = await _confirmAction(
      l10n.matchRemoveGoalTitle,
      ourTeam
          ? l10n.matchConfirmRemoveGoalOur
          : l10n.matchConfirmRemoveGoalRival,
    );
    if (!confirmed) return;

    try {
      final supabase = Supabase.instance.client;

      final String eventTypeFilter = ourTeam ? 'scoreGoal' : 'concedeGoal';

      final result = await supabase
          .from('match_events')
          .select()
          .eq('match_id', _match.id)
          .eq('type', eventTypeFilter)
          .order('minute', ascending: false)
          .limit(1);

      if (result.isEmpty) {
        _showSnack(
          l10n.matchGoalNotFoundInDb,
          error: true,
        );
        return;
      }

      final row = result.first;

      final String? eventTypeString = row['type'] as String?;
      final MatchEventEnum eventType = eventTypeString != null
          ? MatchEventEnum.values.firstWhere(
              (e) => e.toString() == 'MatchEventEnum.$eventTypeString',
              orElse: () => MatchEventEnum.scoreGoal,
            )
          : MatchEventEnum.scoreGoal;

      final event = MatchEvent(
        id: row['id'] as int,
        matchId: _match.id,
        playerId1: row['player_id1'] as int?,
        playerId2: row['player_id2'] as int?,
        minute: supabaseInt(row['minute']) ?? 0,
        type: eventType,
        note: row['note'] as String?,
      );

      final deleteMatchEventUseCase = context.read<DeleteMatchEventUseCase>();
      final deleteResult = await deleteMatchEventUseCase(
        event,
        authState.user,
        widget.team.id,
      );

      await deleteResult.fold<Future<void>>(
        (failure) async {
          _showSnack(failure.message, error: true);
        },
        (_) async {
          await _refreshDerivedMatchData();
          if (mounted) {
            _showSnack(l10n.matchGoalRemovedOk);
          }
        },
      );
    } catch (e) {
      _showSnack(l10n.matchGoalRemoveFail, error: true);
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
      final supabase = Supabase.instance.client;
      final lineupResult = await supabase
          .from('match_lineup')
          .select('player_id')
          .eq('match_id', _match.id);

      playerIds = lineupResult
          .map<int>((row) => row['player_id'] as int)
          .toSet();
    } catch (e) {
      debugPrint('Error loading match_lineup for convocation: $e');
      // playerIds se queda vacío y más abajo mostraremos
      // todos los jugadores del equipo como fallback.
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
      final supabase = Supabase.instance.client;

      final lineupRows = await supabase
          .from('match_lineup')
          .select('player_id, position')
          .eq('match_id', _match.id);

      if (!mounted) return;

      final List<Player?> newPositions = List<Player?>.filled(
        _positionPlayers.length,
        null,
      );

      for (final row in lineupRows as List) {
        final int? playerId = row['player_id'] as int?;
        final int? pos = row['position'] as int?;
        if (playerId == null || pos == null) continue;
        if (pos < 0 || pos >= newPositions.length) continue;

        final player = _convokedPlayers.firstWhere(
          (p) => p.id == playerId,
          orElse: () => const Player(teamId: 0, firstName: ''),
        );

        if (player.id != 0) {
          newPositions[pos] = player;
        }
      }

      setState(() {
        _positionPlayers = newPositions;
      });
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

  Future<void> _onPlayerActionRequested(Player player) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isExternal) {
      _showSnack(
        l10n.matchSpectatorNoPlayerActions,
        error: true,
      );
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
      case MatchPlayerActionType.ballRecovery:
        return l10n.matchActionLabelBallRecovery;
      case MatchPlayerActionType.yellowCard:
        return l10n.matchActionLabelYellowCard;
      case MatchPlayerActionType.redCard:
        return l10n.matchActionLabelRedCard;
      case MatchPlayerActionType.badPass:
        return l10n.matchActionLabelBadPass;
      case MatchPlayerActionType.badPlay:
        return l10n.matchActionLabelBadPlay;
    }
  }

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
        case MatchPlayerActionType.ballRecovery:
          type = MatchEventEnum.ballRecovery;
          note = 'Balón recuperado';
          break;
        case MatchPlayerActionType.badPass:
          type = MatchEventEnum.badPass;
          note = 'Pase impreciso';
          break;
        case MatchPlayerActionType.badPlay:
          type = MatchEventEnum.badPlay;
          note = 'Jugada imprecisa';
          break;
        case MatchPlayerActionType.yellowCard:
          type = MatchEventEnum.yellowCard;
          note = 'Tarjeta amarilla';
          break;
        case MatchPlayerActionType.redCard:
          type = MatchEventEnum.redCard;
          note = 'Tarjeta roja';
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
              duration: const Duration(seconds: 1),
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
          final supabase = Supabase.instance.client;
          await supabase
              .from('matches')
              .update({'status': 'halfTime'})
              .eq('id', _match.id);
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
          final supabase = Supabase.instance.client;
          await supabase
              .from('matches')
              .update({
                'status': 'secondHalf',
                'date': secondHalfStart.toIso8601String(),
                'hour': secondHalfStart.toIso8601String(),
              })
              .eq('id', _match.id);
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
          final counts = await _queryScoreCountsFromEvents();
          final finishedMatch = Match(
            id: _match.id,
            teamId: _match.teamId,
            opponent: _match.opponent,
            goalsScored: counts?.scored ?? _match.goalsScored,
            goalsConceded: counts?.conceded ?? _match.goalsConceded,
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
                  getLatestFormationNoteByMatchUseCase:
                      getLatestFormationNoteByMatchUseCase,
                  loadErrorMessage: loadErrorMessage,
                )..load(),
                child: MatchStatsPage(match: finishedMatch),
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

    Widget clockWidget() {
      final mainSeconds = _mainClockSeconds();
      final extraSeconds = _extraClockSeconds();

      if (extraSeconds <= 0) {
        return Text(
          _formatTime(mainSeconds),
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            letterSpacing: -0.5,
          ),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(mainSeconds),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(extraSeconds),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.tertiary,
            ),
          ),
        ],
      );
    }

    return TeamBrandedScope(
      team: widget.team,
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenMatchLive),
        centerTitle: true,
        actions: const [TeamQuickNavAppBarButton()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefreshMatchScreen,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.matchScoreAndTime,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              _phaseDisplayLabel(l10n),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: scheme.primaryContainer.withValues(
                              alpha: 0.65,
                            ),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
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
                                widget.team.name,
                                textAlign: TextAlign.end,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${_match.goalsScored}',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: scheme.primary,
                                        ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '—',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: scheme.outline,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    '${_match.goalsConceded}',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: scheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _match.opponent,
                                textAlign: TextAlign.start,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(child: clockWidget()),
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
                          icon: const Icon(Icons.sports_soccer, size: 20),
                          label: Text(l10n.matchOpponentGoal),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _onRemoveGoal(ourTeam: true),
                                child: Text(l10n.matchSubtractOur),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _onRemoveGoal(ourTeam: false),
                                child: Text(l10n.matchSubtractRival),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.matchGoalsFromFieldHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stadium_outlined, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.matchFieldAndFormation,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isExternal)
                            Chip(
                              label: Text(
                                _selectedFormation,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                              side: BorderSide.none,
                            )
                          else
                            FilledButton.tonalIcon(
                              onPressed: _showFormationPicker,
                              icon: const Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                              ),
                              label: Text(_selectedFormation),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ExcludeSemantics(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 420,
                              maxHeight: 320,
                            ),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: MatchFieldWithFormation(
                                formationLines: _formationLines,
                                positionPlayers: _positionPlayers,
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
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.groups, color: scheme.primary),
                            const SizedBox(width: 8),
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
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: scheme.primary),
                          const SizedBox(width: 8),
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
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isExternal
                                  ? null
                                  : () => _onLiveEventTapped(_liveEvents[i]),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          scheme.surfaceContainerHigh,
                                      child: Icon(
                                        _iconForLiveEventKey(
                                          _canonicalEventTypeKey(
                                            _liveEvents[i]['type'],
                                          ),
                                        ),
                                        size: 18,
                                        color: scheme.primary,
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
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              children:
                                                  _liveEventDescriptionSpans(
                                                l10n,
                                                _liveEvents[i],
                                                theme.textTheme.bodyMedium!
                                                    .copyWith(
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
                                                    _liveEvents[i]['minute'],
                                                  ) ??
                                                  0;
                                              final half = _eventMatchHalf(
                                                _liveEvents[i],
                                                _resolvedSecondHalfStart(),
                                              );
                                              return _formatLiveEventMinuteLine(
                                                m,
                                                half,
                                              );
                                            }(),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
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
              const SizedBox(height: 16),
              BlocBuilder<LoadingCubit, bool>(
                builder: (context, isLoading) {
                  final schemeBtn = Theme.of(context).colorScheme;
                  return FilledButton(
                    onPressed: (isLoading || isExternal)
                        ? null
                        : _onBottomButtonPressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        : Text(
                            _bottomButtonLabel(l10n),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
