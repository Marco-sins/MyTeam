import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/attendance.dart';
import 'package:tfg1/domain/entities/player.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/attendance/create_attendance_use_case.dart';
import 'package:tfg1/domain/usecase/attendance/get_attendance_by_date_use_case.dart';
import 'package:tfg1/domain/usecase/attendance/update_attendance_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_cubit.dart';
import 'package:tfg1/presentation/team/bloc/team_detail_state.dart';
import 'package:tfg1/presentation/team/widgets/team_bottom_bar.dart';

enum AttendanceStatus { present, absent }

class AttendancePage extends StatefulWidget {
  final Team team;

  const AttendancePage({super.key, required this.team});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final Map<int, AttendanceStatus> _statuses = {};
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Cargamos la asistencia existente para la fecha inicial (hoy)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingAttendanceForSelectedDate();
    });
  }

  int _presentCount(List<Player> players) {
    if (players.isEmpty) return 0;
    int present = 0;
    for (final p in players) {
      final status = _statuses[p.id] ?? AttendanceStatus.present;
      if (status == AttendanceStatus.present) {
        present++;
      }
    }
    return present;
  }

  int _absentCount(List<Player> players) {
    if (players.isEmpty) return 0;
    int absent = 0;
    for (final p in players) {
      final status = _statuses[p.id] ?? AttendanceStatus.present;
      if (status == AttendanceStatus.absent) {
        absent++;
      }
    }
    return absent;
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _formattedDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Encabezado con escudo y nombre de equipo centrado
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.shield, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.team.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Fila fecha + calendario + contador presentes/ausentes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
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
                      await _loadExistingAttendanceForSelectedDate();
                    }
                  },
                ),
                const Spacer(),
                BlocBuilder<TeamDetailCubit, TeamDetailState>(
                  builder: (context, state) {
                    if (state is! TeamDetailLoaded) {
                      return const SizedBox.shrink();
                    }
                    final players = List<Player>.from(state.players);
                    final present = _presentCount(players);
                    final absent = _absentCount(players);
                    return Row(
                      children: [
                        Text(
                          '$present',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$absent',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: const [
                SizedBox(
                  width: 40,
                  child: Text(
                    '#',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jugador',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Asiste',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Ausencia',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<TeamDetailCubit, TeamDetailState>(
              builder: (context, state) {
                if (state is TeamDetailLoading || state is TeamDetailInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TeamDetailError) {
                  return Center(child: Text(state.message));
                }
                if (state is TeamDetailLoaded) {
                  final players = List<Player>.from(state.players)
                    ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

                  if (players.isEmpty) {
                    return const Center(
                      child: Text('No hay jugadores en la plantilla'),
                    );
                  }

                  return ListView.separated(
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final currentStatus =
                          _statuses[player.id] ?? AttendanceStatus.present;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6,
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
                            SizedBox(
                              width: 60,
                              child: Center(
                                child: _AttendanceOption(
                                  label: 'A',
                                  selectedColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  isSelected:
                                      currentStatus == AttendanceStatus.present,
                                  onTap: () => _setStatus(
                                    player.id,
                                    AttendanceStatus.present,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: Center(
                                child: _AttendanceOption(
                                  label: 'X',
                                  selectedColor: Colors.red,
                                  isSelected:
                                      currentStatus == AttendanceStatus.absent,
                                  onTap: () => _setStatus(
                                    player.id,
                                    AttendanceStatus.absent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _onSavePressed,
              icon: const Icon(Icons.save),
              label: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setStatus(int playerId, AttendanceStatus status) {
    setState(() {
      _statuses[playerId] = status;
    });
  }

  String _formattedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _loadExistingAttendanceForSelectedDate() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      return;
    }

    final teamState = context.read<TeamDetailCubit>().state;
    if (teamState is! TeamDetailLoaded) {
      return;
    }

    final getAttendanceByDateUseCase = context
        .read<GetAttendanceByDateUseCase>();
    final result = await getAttendanceByDateUseCase(
      _selectedDate,
      authState.user,
      widget.team.id,
    );

    if (!mounted) return;

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final list = result.getOrElse(() => []);
    final players = List<Player>.from(teamState.players);
    final newStatuses = <int, AttendanceStatus>{};

    if (list.isEmpty) {
      // Si no hay registros ese día, dejamos los estados vacíos:
      // por defecto se consideran presentes en la UI.
      setState(() {
        _statuses.clear();
      });
      return;
    }

    // Mapa rápido de asistencia existente por jugador
    final existingByPlayer = <int, Attendance>{
      for (final a in list) a.playerId: a,
    };

    // Para cada jugador de la plantilla:
    // - si tiene registro, usamos su valor
    // - si no tiene registro, lo marcamos como ausente
    for (final p in players) {
      final existing = existingByPlayer[p.id];
      if (existing == null) {
        newStatuses[p.id] = AttendanceStatus.absent;
      } else {
        newStatuses[p.id] = existing.attended
            ? AttendanceStatus.present
            : AttendanceStatus.absent;
      }
    }

    setState(() {
      _statuses
        ..clear()
        ..addAll(newStatuses);
    });
  }

  Future<void> _onSavePressed() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para guardar la asistencia'),
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

    final getAttendanceByDateUseCase = context
        .read<GetAttendanceByDateUseCase>();
    final existingResult = await getAttendanceByDateUseCase(
      _selectedDate,
      authState.user,
      widget.team.id,
    );

    if (existingResult.isLeft()) {
      final failure = existingResult.fold((f) => f, (_) => throw Exception());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
      );
      return;
    }

    final existingList = existingResult.getOrElse(() => []);
    final existingByPlayer = <int, Attendance>{
      for (final a in existingList) a.playerId: a,
    };

    final createAttendanceUseCase = context.read<CreateAttendanceUseCase>();
    final updateAttendanceUseCase = context.read<UpdateAttendanceUseCase>();

    final players = List<Player>.from(teamState.players)
      ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

    for (final player in players) {
      final status = _statuses[player.id] ?? AttendanceStatus.present;
      final attended = status != AttendanceStatus.absent;
      final existing = existingByPlayer[player.id];

      if (existing == null) {
        final newAttendance = Attendance(
          id: 0,
          teamId: widget.team.id,
          playerId: player.id,
          date: _selectedDate,
          attended: attended,
        );
        final res = await createAttendanceUseCase(
          newAttendance,
          authState.user,
        );
        if (res.isLeft()) {
          final failure = res.fold((f) => f, (_) => throw Exception());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        if (existing.attended == attended) continue;
        final updated = Attendance(
          id: existing.id,
          teamId: existing.teamId,
          playerId: existing.playerId,
          date: _selectedDate,
          attended: attended,
        );
        final res = await updateAttendanceUseCase(updated, authState.user);
        if (res.isLeft()) {
          final failure = res.fold((f) => f, (_) => throw Exception());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Asistencia guardada correctamente'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(true);
  }
}

class _AttendanceOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _AttendanceOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isSelected ? selectedColor : Colors.grey.shade200,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
