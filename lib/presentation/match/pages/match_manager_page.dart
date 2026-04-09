import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/enum/match_event_enum.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/entities/match_event.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/match/finish_match_use_case.dart';
import 'package:tfg1/domain/usecase/match/start_match_use_case.dart';
import 'package:tfg1/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:tfg1/domain/usecase/match_event/save_match_event_use_case.dart';
import 'package:tfg1/domain/usecase/match_event/delete_match_event_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/common/loading_cubit.dart';

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

  // Formaciones disponibles (solo líneas de jugadores de campo: defensa → delantero)
  final Map<String, List<int>> _formationOptions = {
    '3-2-1': [3, 2, 1],
    '2-3-1': [2, 3, 1],
    '2-2-2': [2, 2, 2],
  };

  // Incluye portero (1) + líneas de jugadores de campo
  late List<int> _formationLines;
  late String _selectedFormation;

  late List<Player?> _positionPlayers;
  Player? _selectedPlayer;
  List<int?>? _pendingPositionPlayerIds;

  Timer? _timer;
  int _elapsedSeconds = 0;
  Duration _firstHalfDuration = Duration.zero;
  _MatchPhase _phase = _MatchPhase.notStarted;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    final saved = _savedLineups[_match.id];
    if (saved != null && _formationOptions.containsKey(saved.formationKey)) {
      _selectedFormation = saved.formationKey;
      _pendingPositionPlayerIds = saved.playerIds;
    } else {
      _selectedFormation = '3-2-1';
      _pendingPositionPlayerIds = null;
    }

    final outfieldLines = _formationOptions[_selectedFormation]!;
    _formationLines = [1, ...outfieldLines];

    final totalPositions = _formationLines.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    _positionPlayers = List<Player?>.filled(totalPositions, null);
    _loadConvocationPlayers();
    // Cargar marcador y formación iniciales desde los eventos guardados en BD
    _reloadScoreFromEvents();
    _loadLastFormationFromEvents();
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
      if (!_isTimerRunning) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
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

  void _saveCurrentLineup() {
    final playerIds = _positionPlayers.map((p) => p?.id).toList();
    _savedLineups[_match.id] = _SavedLineupState(
      formationKey: _selectedFormation,
      playerIds: playerIds,
    );
  }

  void _changeFormation(String newKey) {
    setState(() {
      _selectedFormation = newKey;
      final outfieldLines = _formationOptions[newKey]!;
      _formationLines = [1, ...outfieldLines];
      _selectedPlayer = null;
      _pendingPositionPlayerIds = null;
    });
    _saveFormationEvent();
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

  Widget _buildFieldWithFormation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth;
        final fieldHeight = constraints.maxHeight;
        final rows = _formationLines.length;

        final List<Widget> children = [
          Positioned.fill(
            child: Image.asset('media/campo.png', fit: BoxFit.contain),
          ),
        ];

        int positionNumber = 1;
        for (int row = 0; row < rows; row++) {
          // Invertimos las filas para que el portero (primera línea) quede abajo
          final displayRow = rows - 1 - row;
          final countInRow = _formationLines[row];
          final top = fieldHeight * ((displayRow + 1) / (rows + 1));

          for (int col = 0; col < countInRow; col++) {
            final left = fieldWidth * ((col + 1) / (countInRow + 1));
            final index = positionNumber - 1;
            final assignedPlayer = index < _positionPlayers.length
                ? _positionPlayers[index]
                : null;
            final displayNumber = assignedPlayer?.number?.toString() ?? '';

            children.add(
              Positioned(
                left: left - 16,
                top: top - 16,
                child: GestureDetector(
                  onTap: () {
                    if (_selectedPlayer == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Selecciona primero un jugador en la lista',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Si el jugador seleccionado ya está en el campo y
                    // la posición destino también tiene jugador, hacemos
                    // un intercambio de posiciones sin registrar sustitución.
                    final existingIndex = _positionPlayers.indexWhere(
                      (p) => p != null && p!.id == _selectedPlayer!.id,
                    );

                    if (existingIndex != -1 && assignedPlayer != null) {
                      setState(() {
                        _positionPlayers[existingIndex] = assignedPlayer;
                        _positionPlayers[index] = _selectedPlayer;
                        _selectedPlayer = null;
                      });
                      return;
                    }

                    // Sustitución normal: entra jugador (desde banquillo
                    // o sin posición previa) y sale el que estaba en
                    // esta posición.
                    setState(() {
                      if (existingIndex != -1) {
                        _positionPlayers[existingIndex] = null;
                      }

                      _positionPlayers[index] = _selectedPlayer;
                      _selectedPlayer = null;
                    });
                    _saveSubstitutionEvent(
                      playerIn: _positionPlayers[index]!,
                      playerOut: assignedPlayer,
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: assignedPlayer != null
                        ? Colors.greenAccent
                        : Colors.white.withOpacity(0.85),
                    child: Text(
                      displayNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            );

            positionNumber++;
          }
        }

        return Stack(children: children);
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _currentMatchMinute() {
    final baseMinutes = _elapsedSeconds ~/ 60;
    if (_phase == _MatchPhase.secondHalf) {
      // Por ahora sumamos 35 minutos en la segunda parte
      return baseMinutes + 35;
    }
    return baseMinutes;
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
        );
      });
    } catch (_) {
      // Si falla la carga, dejamos el marcador tal como está
    }
  }

  Future<void> _loadLastFormationFromEvents() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('match_events')
          .select('type, note, minute')
          .eq('match_id', _match.id)
          .eq('type', 'formation')
          .order('minute', ascending: false)
          .limit(1);

      if (result.isEmpty) return;

      final row = result.first as Map<String, dynamic>;
      final formation = (row['note'] as String?)?.trim();
      if (formation == null || !_formationOptions.containsKey(formation)) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedFormation = formation;
        final outfieldLines = _formationOptions[formation]!;
        _formationLines = [1, ...outfieldLines];
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
      final saveMatchEventUseCase = context.read<SaveMatchEventUseCase>();
      final minute = _currentMatchMinute();
      final event = MatchEvent(
        id: 0,
        matchId: _match.id,
        playerId1: null,
        playerId2: null,
        minute: minute,
        type: ourTeam ? MatchEventEnum.scoreGoal : MatchEventEnum.concedeGoal,
        note: ourTeam ? 'Gol de nuestro equipo' : 'Gol del rival',
      );

      final result = await saveMatchEventUseCase(
        event,
        authState.user,
        widget.team.id,
      );

      result.fold((failure) => _showSnack(failure.message, error: true), (_) {
        _reloadScoreFromEvents();
        _showSnack('Gol registrado correctamente');
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

      final row = result.first as Map<String, dynamic>;

      final String? eventTypeString = row['type'] as String?;
      final MatchEventEnum eventType = eventTypeString != null
          ? MatchEventEnum.values.firstWhere(
              (e) => e.toString() == 'MatchEventEnum.' + eventTypeString,
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
        _showSnack('Gol eliminado correctamente');
      });
    } catch (e) {
      _showSnack('No se ha podido quitar el gol', error: true);
    }
  }

  Future<void> _persistPositions(String reason) async {
    // Método legado: ya no se usa para guardar posiciones.
  }

  Future<void> _loadConvocationPlayers() async {
    setState(() {
      _loadingPlayers = true;
      _loadError = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final lineupResult = await supabase
          .from('match_lineup')
          .select('player_id')
          .eq('match_id', _match.id);

      final playerIds = lineupResult
          .map<int>((row) => row['player_id'] as int)
          .toSet();

      final getPlayersByTeamUseCase = context.read<GetPlayersByTeamUseCase>();
      final playersResult = await getPlayersByTeamUseCase(widget.team.id);

      playersResult.fold(
        (failure) {
          setState(() {
            _loadError = failure.message;
            _loadingPlayers = false;
          });
        },
        (players) {
          final convoked =
              players.where((p) => playerIds.contains(p.id)).toList()
                ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
          setState(() {
            _convokedPlayers
              ..clear()
              ..addAll(convoked);
            _loadingPlayers = false;
          });

          _restorePositionsIfSaved();
          // Una vez cargados los jugadores convocados, reconstruimos
          // quién está jugando según los eventos de sustitución.
          _loadPositionsFromEvents();
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

      // Obtenemos la información de titulares iniciales desde match_lineup
      final lineupRows = await supabase
          .from('match_lineup')
          .select('player_id, is_start')
          .eq('match_id', _match.id);

      final Set<int> onField = {};
      for (final row in lineupRows) {
        final int playerId = row['player_id'] as int;
        final bool isStart = row['is_start'] as bool? ?? false;
        if (isStart) {
          onField.add(playerId);
        }
      }

      // Aplicamos todas las sustituciones en orden de minuto para saber
      // quién está en el campo al final.
      final subsResult = await supabase
          .from('match_events')
          .select('type, player_id1, player_id2, minute')
          .eq('match_id', _match.id)
          .eq('type', 'substitution')
          .order('minute', ascending: true);

      for (final row in subsResult) {
        final rawType = row['type'];
        final typeString = rawType?.toString().split('.').last;
        if (typeString != 'substitution') continue;

        final int? inId = row['player_id1'] as int?;
        final int? outId = row['player_id2'] as int?;

        if (outId != null) {
          onField.remove(outId);
        }
        if (inId != null) {
          onField.add(inId);
        }
      }

      if (!mounted) return;

      // Construimos la lista de jugadores que están en el campo
      final List<Player> starters =
          _convokedPlayers.where((p) => onField.contains(p.id)).toList()
            ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

      if (starters.isEmpty) return;

      final List<Player?> newPositions = List<Player?>.filled(
        _positionPlayers.length,
        null,
      );

      for (int i = 0; i < starters.length && i < newPositions.length; i++) {
        newPositions[i] = starters[i];
      }

      setState(() {
        _positionPlayers = newPositions;
      });
    } catch (e) {
      debugPrint('Error loading positions from events: $e');
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
            ),
          );
          _matchStartTimes[_match.id] = startTime;
          _saveCurrentLineup();
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
      // Pasar a descanso: guardamos duración de la primera parte
      _isTimerRunning = false;
      _timer?.cancel();
      _firstHalfDuration = Duration(seconds: _elapsedSeconds);
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
            ),
          );
          Navigator.of(context).pop(true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreText =
        '${widget.team.name} ${_match.goalsScored} - ${_match.goalsConceded} ${_match.opponent}';

    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de partido'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                // Cronómetro
                Center(
                  child: Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Botones de goles encima del campo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _onAddGoal(ourTeam: true),
                      child: const Text(
                        '+ Gol mi equipo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _onAddGoal(ourTeam: false),
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
                      onPressed: () => _onRemoveGoal(ourTeam: true),
                      child: const Text('Quitar gol mi equipo'),
                    ),
                    TextButton(
                      onPressed: () => _onRemoveGoal(ourTeam: false),
                      child: const Text('Quitar gol rival'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: DropdownButton<String>(
                    value: _selectedFormation,
                    items: _formationOptions.keys
                        .map(
                          (key) => DropdownMenuItem<String>(
                            value: key,
                            child: Text(key),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _changeFormation(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Campo con la formación. Damos una altura fija razonable
                // dentro del scroll para que quepa en móviles pequeños.
                SizedBox(
                  height: 260,
                  child: Center(child: _buildFieldWithFormation()),
                ),
                const SizedBox(height: 16),
                // Tabla de convocatoria embebida en el scroll
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: _buildConvocationTable(scrollingChild: true),
                ),
                const SizedBox(height: 16),
                BlocBuilder<LoadingCubit, bool>(
                  builder: (context, isLoading) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onBottomButtonPressed,
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
        ),
      ),
    );
  }

  Widget _buildConvocationTable({bool scrollingChild = false}) {
    if (_loadingPlayers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(child: Text(_loadError!));
    }

    if (_convokedPlayers.isEmpty) {
      return const Center(
        child: Text('No hay jugadores convocados para este partido'),
      );
    }

    final listView = ListView.separated(
      shrinkWrap: scrollingChild,
      physics: scrollingChild ? const ClampingScrollPhysics() : null,
      itemCount: _convokedPlayers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final player = _convokedPlayers[index];
        final dorsal = player.number?.toString() ?? '-';
        final name = player.firstName;
        final lastName = player.lastName ?? '';
        final display = lastName.isNotEmpty
            ? '$dorsal  $name $lastName,'
            : '$dorsal  $name,';
        final assignedIndex = _positionPlayers.indexWhere(
          (p) => p != null && p!.id == player.id,
        );
        final isAssigned = assignedIndex != -1;

        final isSelected = _selectedPlayer?.id == player.id;

        return ListTile(
          title: Text(display),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAssigned) const Icon(Icons.check, color: Colors.green),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(Icons.person_outline, color: Colors.orange),
                ),
            ],
          ),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedPlayer = null;
              } else {
                _selectedPlayer = player;
              }
            });
          },
        );
      },
    );
    return listView;
  }
}
