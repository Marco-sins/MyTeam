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
import 'package:football_manager/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/save_match_event_use_case.dart';
import 'package:football_manager/domain/usecase/match_event/delete_match_event_use_case.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/auth/cubit/auth_state.dart';
import 'package:football_manager/presentation/common/cubit/loading_cubit.dart';
import 'package:football_manager/presentation/match/cubit/match_stats_cubit.dart';
import 'package:football_manager/presentation/match/widgets/match_convocation_table.dart';
import 'package:football_manager/presentation/match/widgets/match_field_with_formation.dart';
import 'package:football_manager/presentation/match/widgets/match_player_action_modal.dart';
import 'package:football_manager/presentation/match/pages/match_stats_page.dart';
import 'package:football_manager/presentation/match/utils/player_rating_utils.dart';

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

class _MatchManagerPageState extends State<MatchManagerPage> {
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
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      final copyCount = totalPositions < old.length ? totalPositions : old.length;
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
        return SimpleDialog(
          title: const Text('Formación'),
          children: [
            for (final key in _formationOptions.keys)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, key),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      key,
                      style: const TextStyle(fontSize: 17),
                    ),
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
    } catch (e) {
      debugPrint('Error saving status change event: $e');
    }
  }

  Future<void> _reloadScoreFromEvents() async {
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

      if (!mounted) return;
      setState(() {
        _match = Match(
          id: _match.id,
          teamId: _match.teamId,
          opponent: _match.opponent,
          goalsScored: scored,
          goalsConceded: conceded,
          date: _match.date,
          hour: _match.hour,
          status: _match.status,
          lineups: _match.lineups,
          isHome: _match.isHome,
        );
      });
    } catch (_) {
      // Si falla la carga, dejamos el marcador tal como está
    }
  }

  Future<void> _recalculatePlayerRatings() async {
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

      if (!mounted) return;
      setState(() {
        _playerRatings = newRatings;
      });
    } catch (e) {
      debugPrint('Error calculating player ratings: $e');
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
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
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
    } catch (e) {
      debugPrint('Error saving substitution event: $e');
    }
  }

  Future<void> _onAddGoal({required bool ourTeam}) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack('Debes iniciar sesión para registrar goles', error: true);
      return;
    }

    final confirmed = await _confirmAction(
      'Confirmar gol',
      ourTeam
          ? '¿Seguro que quieres añadir un gol a tu equipo?'
          : '¿Seguro que quieres añadir un gol al rival?',
    );
    if (!confirmed) return;

    try {
      // Solo permitimos registrar goles del rival desde este botón.
      if (ourTeam) {
        _showSnack(
          'Los goles de tu equipo se registran desde un jugador en el campo',
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

      result.fold((failure) => _showSnack(failure.message, error: true), (_) {
        _reloadScoreFromEvents();
        _showSnack('Gol del rival registrado correctamente');
      });
    } catch (e) {
      _showSnack('No se ha podido registrar el gol', error: true);
    }
  }

  Future<void> _onRemoveGoal({required bool ourTeam}) async {
    final currentGoals = ourTeam ? _match.goalsScored : _match.goalsConceded;
    if (currentGoals <= 0) {
      _showSnack('No hay goles que quitar', error: true);
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnack('Debes iniciar sesión para quitar goles', error: true);
      return;
    }

    final confirmed = await _confirmAction(
      'Quitar gol',
      ourTeam
          ? '¿Seguro que quieres quitar un gol a tu equipo?'
          : '¿Seguro que quieres quitar un gol al rival?',
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
          'No se ha encontrado el gol en la base de datos',
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
        minute: (row['minute'] as int?) ?? 0,
        type: eventType,
        note: row['note'] as String?,
      );

      final deleteMatchEventUseCase = context.read<DeleteMatchEventUseCase>();
      final deleteResult = await deleteMatchEventUseCase(
        event,
        authState.user,
        widget.team.id,
      );

      deleteResult.fold((failure) => _showSnack(failure.message, error: true), (
        _,
      ) {
        _reloadScoreFromEvents();
        _recalculatePlayerRatings();
        _showSnack('Gol eliminado correctamente');
      });
    } catch (e) {
      _showSnack('No se ha podido quitar el gol', error: true);
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
        },
      );
    } catch (e) {
      setState(() {
        _loadError = 'No se ha podido cargar la convocatoria';
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
        final int? p1 = row['player_id1'] as int?;
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

      if (!mounted) return;

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
    } catch (e) {
      debugPrint('Error loading discipline state from events: $e');
    }
  }

  String _bottomButtonLabel() {
    switch (_phase) {
      case _MatchPhase.notStarted:
        return 'Empezar partido';
      case _MatchPhase.firstHalf:
        return 'Descanso';
      case _MatchPhase.halfTime:
        return 'Reanudar partido';
      case _MatchPhase.secondHalf:
        return 'Terminar partido';
    }
  }

  Future<void> _onPlayerActionRequested(Player player) async {
    if (_isExternal) {
      _showSnack(
        'Modo espectador: no puedes registrar acciones de jugadores',
        error: true,
      );
      return;
    }
    final action = await showMatchPlayerActionModal(context, player);

    if (action == null) return;

    final label = _playerActionLabel(action);
    final confirmed = await _confirmAction(
      'Confirmar acción',
      '¿Seguro que quieres registrar "${label}" para ${player.fullName}?',
    );
    if (!confirmed) return;

    await _savePlayerActionEvent(player, action);
  }

  String _playerActionLabel(MatchPlayerActionType action) {
    switch (action) {
      case MatchPlayerActionType.goal:
        return 'Gol';
      case MatchPlayerActionType.ownGoal:
        return 'Gol en propia';
      case MatchPlayerActionType.goodPass:
        return 'Buen pase';
      case MatchPlayerActionType.keyPass:
        return 'Pase clave';
      case MatchPlayerActionType.badPass:
        return 'Mal pase';
      case MatchPlayerActionType.badPlay:
        return 'Mala jugada';
      case MatchPlayerActionType.goodPlay:
        return 'Buena jugada';
      case MatchPlayerActionType.keyPlay:
        return 'Jugada clave';
      case MatchPlayerActionType.losePosition:
        return 'Pierde posición';
      case MatchPlayerActionType.losePossession:
        return 'Pierde posesión';
      case MatchPlayerActionType.winPossession:
        return 'Gana posesión';
      case MatchPlayerActionType.goodSave:
        return 'Buena parada';
      case MatchPlayerActionType.amazingSave:
        return 'Increíble parada';
      case MatchPlayerActionType.concededGoal:
        return 'Gol concedido';
      case MatchPlayerActionType.yellowCard:
        return 'Tarjeta amarilla';
      case MatchPlayerActionType.redCard:
        return 'Tarjeta roja';
    }
  }

  Future<void> _savePlayerActionEvent(
    Player player,
    MatchPlayerActionType action,
  ) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        _showSnack('Debes iniciar sesión para registrar acciones', error: true);
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
        case MatchPlayerActionType.ownGoal:
          type = MatchEventEnum.ownGoal;
          note = 'Gol en propia';
          break;
        case MatchPlayerActionType.goodPass:
          type = MatchEventEnum.statusChange;
          note = 'Buen pase';
          break;
        case MatchPlayerActionType.keyPass:
          type = MatchEventEnum.keyPass;
          note = 'Pase clave';
          break;
        case MatchPlayerActionType.badPass:
          type = MatchEventEnum.statusChange;
          note = 'Mal pase';
          break;
        case MatchPlayerActionType.badPlay:
          type = MatchEventEnum.statusChange;
          note = 'Mala jugada';
          break;
        case MatchPlayerActionType.goodPlay:
          type = MatchEventEnum.statusChange;
          note = 'Buena jugada';
          break;
        case MatchPlayerActionType.keyPlay:
          type = MatchEventEnum.statusChange;
          note = 'Jugada clave';
          break;
        case MatchPlayerActionType.losePosition:
          type = MatchEventEnum.statusChange;
          note = 'Pierde posición';
          break;
        case MatchPlayerActionType.losePossession:
          type = MatchEventEnum.statusChange;
          note = 'Pierde posesión';
          break;
        case MatchPlayerActionType.winPossession:
          type = MatchEventEnum.statusChange;
          note = 'Gana posesión';
          break;
        case MatchPlayerActionType.goodSave:
          type = MatchEventEnum.goodSave;
          note = 'Buena parada';
          break;
        case MatchPlayerActionType.amazingSave:
          type = MatchEventEnum.goodSave;
          note = 'Increíble parada';
          break;
        case MatchPlayerActionType.concededGoal:
          type = MatchEventEnum.concedeGoal;
          note = 'Gol concedido';
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

      result.fold((failure) => _showSnack(failure.message, error: true), (_) {
        _reloadScoreFromEvents();
        _recalculatePlayerRatings();
        if (type == MatchEventEnum.yellowCard ||
            type == MatchEventEnum.redCard) {
          _handleDisciplineForCard(player);
        }
        _showSnack('Acción registrada para ${player.fullName}');
      });
    } catch (e) {
      _showSnack('No se ha podido registrar la acción', error: true);
    }
  }

  Future<void> _handleDisciplineForCard(Player player) async {
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

      if (!hasRed && yellowCount < 2) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _sentOffPlayerIds.add(player.id);

        final cleared = List<Player?>.from(_positionPlayers);
        for (int i = 0; i < cleared.length; i++) {
          final p = cleared[i];
          if (p != null && p.id == player.id) {
            cleared[i] = null;
          }
        }
        _positionPlayers = cleared;

        if (_selectedPlayer?.id == player.id) {
          _selectedPlayer = null;
        }
      });

      _showSnack(
        yellowCount >= 2
            ? '${player.fullName} expulsado por doble amarilla'
            : '${player.fullName} expulsado',
        error: true,
      );
    } catch (e) {
      debugPrint('Error handling card discipline: $e');
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

        return AlertDialog(
          title: const Text('Seleccionar asistente'),
          content: SizedBox(
            width: 320,
            height: 320,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Sin asistencia'),
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: assistCandidates.length,
                    itemBuilder: (context, index) {
                      final p = assistCandidates[index];
                      final dorsal = p.number?.toString() ?? '-';
                      return ListTile(
                        title: Text('$dorsal  ${p.fullName}'),
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
              child: const Text('Cancelar'),
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

      goalResult.fold(
        (failure) {
          _showSnack('No se ha podido registrar el gol', error: true);
        },
        (_) {
          _reloadScoreFromEvents();
          _recalculatePlayerRatings();
          _showSnack('Gol registrado para ${player.fullName}');
        },
      );
    } catch (e) {
      _showSnack('No se ha podido registrar el gol', error: true);
    }
  }

  Future<void> _onBottomButtonPressed() async {
    final loadingCubit = context.read<LoadingCubit>();

    if (_phase == _MatchPhase.notStarted) {
      if (!_allPositionsFilled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debes colocar todos los jugadores antes de empezar el partido',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para empezar el partido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final confirmed = await _confirmAction(
        'Empezar partido',
        '¿Seguro que quieres empezar el partido?',
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
            const SnackBar(
              content: Text('Partido empezado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
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
        'Ir al descanso',
        '¿Seguro que quieres pasar al descanso?',
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
          const SnackBar(
            content: Text('Debes iniciar sesión para pausar el partido'),
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
            const SnackBar(
              content: Text('No se ha podido actualizar el estado del partido'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          loadingCubit.stop();
        }
      }
    } else if (_phase == _MatchPhase.halfTime) {
      final confirmed = await _confirmAction(
        'Reanudar partido',
        '¿Seguro que quieres empezar la 2ª parte?',
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
          const SnackBar(
            content: Text('Debes iniciar sesión para reanudar el partido'),
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
            const SnackBar(
              content: Text('No se ha podido actualizar el estado del partido'),
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
          const SnackBar(
            content: Text('Debes iniciar sesión para terminar el partido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Terminar partido'),
          content: const Text(
            '¿Seguro que quieres terminar el partido? Se guardarán las estadísticas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Terminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Guardamos evento de final de partido
      final minute = _currentMatchMinute();
      _saveStatusChangeEvent(MatchStatus.finished, minute);

      final finishMatchUseCase = context.read<FinishMatchUseCase>();
      if (loadingCubit.state) return;
      loadingCubit.start();
      final result = await finishMatchUseCase(_match, authState.user);
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
            const SnackBar(
              content: Text('Partido terminado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          // Navegamos directamente a la pantalla de estadísticas del partido
          // y reemplazamos el gestor actual. Al volver, se regresa al menú
          // del equipo (pantalla anterior a este gestor).
          final finishedMatch = Match(
            id: _match.id,
            teamId: _match.teamId,
            opponent: _match.opponent,
            goalsScored: _match.goalsScored,
            goalsConceded: _match.goalsConceded,
            date: _match.date,
            hour: _match.hour,
            status: MatchStatus.finished,
            lineups: _match.lineups,
            isHome: _match.isHome,
          );

          final getPlayersByTeamUseCase =
              context.read() as GetPlayersByTeamUseCase;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => BlocProvider(
                create: (_) => MatchStatsCubit(
                  match: finishedMatch,
                  getPlayersByTeamUseCase: getPlayersByTeamUseCase,
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
    final scoreText =
        '${widget.team.name} ${_match.goalsScored} - ${_match.goalsConceded} ${_match.opponent}';
    final bool isExternal = _isExternal;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de partido'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
                // Marcador grande
                Text(
                  scoreText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                // Cronómetro de la parte actual: tiempo reglamentario + descuento
                Center(
                  child: Builder(
                    builder: (context) {
                      final mainSeconds = _mainClockSeconds();
                      final extraSeconds = _extraClockSeconds();

                      if (extraSeconds <= 0) {
                        // Solo tiempo reglamentario
                        return Text(
                          _formatTime(mainSeconds),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }

                      // Tiempo reglamentario + descuento (aparece el segundo
                      // cronómetro solo cuando se supera el tope de la parte)
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(mainSeconds),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(extraSeconds),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Botones de goles encima del campo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: isExternal
                          ? null
                          : () => _onAddGoal(ourTeam: false),
                      child: const Text(
                        '+ Gol rival',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: isExternal
                          ? null
                          : () => _onRemoveGoal(ourTeam: true),
                      child: const Text('Quitar gol mi equipo'),
                    ),
                    TextButton(
                      onPressed: isExternal
                          ? null
                          : () => _onRemoveGoal(ourTeam: false),
                      child: const Text('Quitar gol rival'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: isExternal
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            _selectedFormation,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _showFormationPicker,
                          icon: const Icon(Icons.grid_view_outlined, size: 20),
                          label: Text(_selectedFormation),
                        ),
                ),
                const SizedBox(height: 8),
                // Campo: excluido del árbol de semánticas para evitar asserts
                // del motor (`parentDataDirty`) con muchos huecos en un Stack
                // dentro de un scroll.
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
                          onPlayerActionRequested: _onPlayerActionRequested,
                          readOnly: isExternal,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                    if (isSentOff) {
                      _showSnack(
                        'Jugador expulsado, no puede volver a entrar',
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
                const SizedBox(height: 16),
                BlocBuilder<LoadingCubit, bool>(
                  builder: (context, isLoading) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (isLoading || isExternal)
                            ? null
                            : _onBottomButtonPressed,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _bottomButtonLabel(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
