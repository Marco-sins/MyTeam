import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/entities/enum/match_status.dart';
import 'package:tfg1/domain/entities/match.dart';
import 'package:tfg1/domain/entities/match_lineup.dart';
import 'package:tfg1/domain/usecase/match/create_match_use_case.dart';
import 'package:tfg1/domain/usecase/player/get_players_by_team_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/common/loading_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';
import 'package:tfg1/presentation/team/pages/team_detail_page.dart';
import 'package:tfg1/presentation/team/widgets/team_bottom_bar.dart';

class ConvocationPage extends StatefulWidget {
  final Team team;

  const ConvocationPage({super.key, required this.team});

  @override
  State<ConvocationPage> createState() => _ConvocationPageState();
}

class _ConvocationPageState extends State<ConvocationPage> {
  final TextEditingController _rivalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Map<int, bool> _calledUp = {}; // playerId -> convocado (true/false)

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _rivalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _calledUpCount(List<Player> players) {
    int count = 0;
    for (final p in players) {
      if (_calledUp[p.id] == true) count++;
    }
    return count;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formattedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formattedTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _toggleCalledUp(int playerId) {
    setState(() {
      final current = _calledUp[playerId] ?? false;
      _calledUp[playerId] = !current;
    });
  }

  Future<void> _onSavePressed() async {
    final loadingCubit = context.read<LoadingCubit>();
    if (loadingCubit.state) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para guardar la convocatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final teamState = context.read<TeamDetailCubit>().state;
    if (teamState is! TeamDetailLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido cargar la plantilla del equipo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rival = _rivalController.text.trim();
    if (rival.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes indicar un rival para la convocatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final players = teamState.players;
    final selectedPlayers = players
        .where((p) => _calledUp[p.id] == true)
        .toList();

    if (selectedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un jugador para convocar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final matchDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Generamos un id temporal dentro del rango de integer
    // de Postgres usando segundos desde epoch.
    final int tempMatchId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final lineups = selectedPlayers
        .map(
          (player) => MatchLineup(
            id: 0,
            playerId: player.id,
            matchId: tempMatchId,
            // En la convocatoria solo marcamos quién está citado;
            // los titulares reales se marcarán al empezar el partido.
            isStarting: false,
          ),
        )
        .toList();

    final match = Match(
      id: tempMatchId,
      teamId: widget.team.id,
      opponent: rival,
      goalsScored: 0,
      goalsConceded: 0,
      date: matchDateTime,
      hour: _formattedTime(_selectedTime),
      status: MatchStatus.notStarted,
      lineups: lineups,
    );

    final createMatchUseCase = context.read<CreateMatchUseCase>();
    loadingCubit.start();
    final result = await createMatchUseCase(match, authState.user);
    if (!mounted) return;
    loadingCubit.stop();

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Convocatoria guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _formattedDate(_selectedDate);
    final String formattedTime = _formattedTime(_selectedTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convocatoria'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  controller: _rivalController,
                  decoration: const InputDecoration(
                    labelText: 'Rival',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                    const Spacer(),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: _pickTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              BlocBuilder<TeamDetailCubit, TeamDetailState>(
                builder: (context, state) {
                  if (state is TeamDetailLoading ||
                      state is TeamDetailInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is TeamDetailError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is TeamDetailLoaded) {
                    final players = List<Player>.from(
                      state.players,
                    )..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

                    if (players.isEmpty) {
                      return const Center(
                        child: Text('No hay jugadores en la plantilla'),
                      );
                    }

                    final calledCount = _calledUpCount(players);

                    return Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: players.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final isCalled = _calledUp[player.id] ?? false;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      player.number?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      player.fullName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _toggleCalledUp(player.id),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCalled
                                            ? Colors.green
                                            : Colors.grey,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        isCalled ? 'Sí' : 'No',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Jugadores convocados: $calledCount',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<LoadingCubit, bool>(
                        builder: (context, isLoading) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: isLoading ? null : _onSavePressed,
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
                                : const Text(
                                    'Guardar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TeamBottomBar(team: widget.team),
    );
  }
}
