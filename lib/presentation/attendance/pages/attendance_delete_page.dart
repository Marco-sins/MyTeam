import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/domain/entities/team.dart';
import 'package:tfg1/domain/usecase/attendance/delete_attendance_day_use_case.dart';
import 'package:tfg1/domain/usecase/attendance/get_attendance_days_by_team_use_case.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_state.dart';

class AttendanceDeletePage extends StatefulWidget {
  final Team team;

  const AttendanceDeletePage({super.key, required this.team});

  @override
  State<AttendanceDeletePage> createState() => _AttendanceDeletePageState();
}

class _AttendanceDeletePageState extends State<AttendanceDeletePage> {
  late Future<dynamic> _daysFuture;

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  void _loadDays() {
    _daysFuture = context.read<GetAttendanceDaysByTeamUseCase>().call(
      widget.team.id,
    );
  }

  String _formattedDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminar asistencia'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: _daysFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('No se han podido cargar los días de asistencia'),
              );
            }

            final either = snapshot.data!;
            return either.fold((failure) => Center(child: Text(failure.message)), (
              dates,
            ) {
              if (dates.isEmpty) {
                return const Center(
                  child: Text('No hay días de entrenamiento registrados'),
                );
              }

              return ListView.builder(
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index] as DateTime;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(_formattedDate(date)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          final authState = context.read<AuthCubit>().state;
                          if (authState is! Authenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Debes iniciar sesión para borrar asistencia',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar asistencia'),
                              content: Text(
                                '¿Seguro que quieres eliminar la asistencia del día ${_formattedDate(date)}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final deleteAttendanceDayUseCase = context
                              .read<DeleteAttendanceDayUseCase>();
                          final result = await deleteAttendanceDayUseCase(
                            date,
                            widget.team.id,
                            authState.user,
                          );

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
                                  content: Text(
                                    'Asistencia del día eliminada correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.of(context).pop(true);
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            });
          },
        ),
      ),
    );
  }
}
