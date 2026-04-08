import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/match/finish_match_use_case.dart';
import 'package:tfg1/domain/usecase/match/start_match_use_case.dart';
import 'package:tfg1/domain/usecase/player/get_players_by_team_use_case.dart';
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
    // Si el partido ya está en juego al entrar, arrancamos el cronómetro.
    if (_match.status == MatchStatus.inProgress) {
      _phase = _MatchPhase.firstHalf;
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
      final totalPositions = _formationLines.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      _positionPlayers = List<Player?>.filled(totalPositions, null);
      _selectedPlayer = null;
      _pendingPositionPlayerIds = null;
    });
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

                    setState(() {
                      // Liberar posición anterior de este jugador (si la tiene)
                      final existingIndex = _positionPlayers.indexWhere(
                        (p) => p != null && p!.id == _selectedPlayer!.id,
                      );
                      if (existingIndex != -1) {
                        _positionPlayers[existingIndex] = null;
                      }

                      // Asignar jugador seleccionado a esta posición
                      _positionPlayers[index] = _selectedPlayer;
                      _selectedPlayer = null;
                    });
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
        },
      );
    } catch (e) {
      setState(() {
        _loadError = 'No se ha podido cargar la convocatoria';
        _loadingPlayers = false;
      });
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
              status: MatchStatus.inProgress,
              lineups: _match.lineups,
            );
            _phase = _MatchPhase.firstHalf;
            _elapsedSeconds = 0;
          });
          _startTimer();
        },
      );
    } else if (_phase == _MatchPhase.firstHalf) {
      // Pasar a descanso: guardamos duración de la primera parte
      _isTimerRunning = false;
      _timer?.cancel();
      _firstHalfDuration = Duration(seconds: _elapsedSeconds);
      setState(() {
        _phase = _MatchPhase.halfTime;
      });
    } else if (_phase == _MatchPhase.halfTime) {
      // Reanudar segunda parte
      setState(() {
        _elapsedSeconds = 0;
        _phase = _MatchPhase.secondHalf;
      });
      _startTimer();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              scoreText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
            Expanded(
              child: Column(
                children: [
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
                  Expanded(
                    flex: 2,
                    child: Center(child: _buildFieldWithFormation()),
                  ),
                  const SizedBox(height: 16),
                  Expanded(flex: 3, child: _buildConvocationTable()),
                ],
              ),
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
                              valueColor: AlwaysStoppedAnimation(Colors.white),
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

  Widget _buildConvocationTable() {
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

    return ListView.separated(
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
  }
}
