import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/data/datasource/attendance_remote_datasource.dart';
import 'package:football_manager/data/repositories/attendance_repository.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';

class AttendanceSummaryTable extends StatelessWidget {
  final Team team;
  final List<Player> players;

  const AttendanceSummaryTable({
    super.key,
    required this.team,
    required this.players,
  });

  Future<_AttendanceMatrix> _loadMatrix() async {
    final supabase = Supabase.instance.client;
    final attendanceRepository = AttendanceRepository(
      AttendanceRemoteDatasource(supabase),
    );
    final result = await attendanceRepository.getAttendances();
    return result.fold((failure) => const _AttendanceMatrix.empty(), (
      attendances,
    ) {
      // Filtramos por equipo
      final teamAttendances = attendances
          .where((a) => a.teamId == team.id)
          .toList();

      if (teamAttendances.isEmpty) {
        return const _AttendanceMatrix.empty();
      }

      // Obtenemos los últimos 6 días registrados (distintos)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final datesSet = teamAttendances
          .map((a) => DateTime(a.date.year, a.date.month, a.date.day))
          .toSet()
          .toList();

      // Ordenamos por cercanía al día de hoy (diferencia en días),
      // de modo que el día más cercano quede más "centrado" visualmente,
      // y los días más lejanos se vayan sumando hacia la derecha.
      datesSet.sort((a, b) {
        final da = (today.difference(a).inDays).abs();
        final db = (today.difference(b).inDays).abs();
        if (da != db) return da.compareTo(db);
        // A igualdad de distancia, más reciente primero
        return b.compareTo(a);
      });

      final recentDates = datesSet.take(6).toList();

      // Construimos matriz playerId -> date -> attendance
      final Map<int, Map<DateTime, Attendance>> matrix = {};
      for (final att in teamAttendances) {
        final keyDate = DateTime(att.date.year, att.date.month, att.date.day);
        if (!recentDates.contains(keyDate)) continue;
        matrix.putIfAbsent(att.playerId, () => {});
        matrix[att.playerId]![keyDate] = att;
      }

      return _AttendanceMatrix(dates: recentDates, data: matrix);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AttendanceMatrix>(
      future: _loadMatrix(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Aunque no haya asistencias, siempre mostramos la plantilla.
        final matrix = snapshot.data ?? const _AttendanceMatrix.empty();
        // Ordenamos jugadores por dorsal para las filas
        final sortedPlayers = List<Player>.from(players)
          ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

        return LayoutBuilder(
          builder: (context, constraints) {
            // Ancho mínimo de la tabla adaptable al tamaño de pantalla
            // (más estrecha en móviles, más ancha en pantallas grandes).
            final double tableMinWidth = constraints.maxWidth.clamp(0.0, 700.0);

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                // Si la tabla es más estrecha que la pantalla,
                // usamos el ancho disponible para poder centrarla.
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Center(
                  child: ConstrainedBox(
                    // Hacemos la tabla más ancha por defecto, pero
                    // adaptando el mínimo al ancho disponible.
                    constraints: BoxConstraints(minWidth: tableMinWidth),
                    child: SingleChildScrollView(
                      // Desplazamiento vertical suave de toda la plantilla
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowHeight: 40,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 48,
                        columns: [
                          const DataColumn(
                            label: SizedBox(
                              width: 40,
                              child: Text(
                                '#',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Jugador',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final date in matrix.dates)
                            DataColumn(
                              label: SizedBox(
                                width: 80,
                                child: Text(
                                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                        ],
                        rows: [
                          for (final player in sortedPlayers)
                            DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      player.number?.toString() ?? '-',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  InkWell(
                                    onTap: () => _showPlayerStatsDialog(
                                      context,
                                      player,
                                      matrix,
                                    ),
                                    child: Text(
                                      player.fullName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                for (final date in matrix.dates)
                                  DataCell(
                                    Center(
                                      child: _buildCell(
                                        matrix,
                                        player.id,
                                        date,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCell(_AttendanceMatrix matrix, int playerId, DateTime date) {
    final attForPlayer = matrix.data[playerId];
    if (attForPlayer == null || !attForPlayer.containsKey(date)) {
      // Si hay asistencia registrada ese día para el equipo pero
      // este jugador no tiene marca, lo consideramos ausente.
      return const Icon(Icons.cancel, color: Colors.redAccent, size: 18);
    }
    final attendance = attForPlayer[date]!;
    return Icon(
      attendance.attended ? Icons.check_circle : Icons.cancel,
      color: attendance.attended ? Colors.green : Colors.redAccent,
      size: 18,
    );
  }

  void _showPlayerStatsDialog(
    BuildContext context,
    Player player,
    _AttendanceMatrix matrix,
  ) {
    final dates = matrix.dates;
    int attendedCount = 0;
    int totalCount = dates.length;

    if (totalCount > 0) {
      for (final date in dates) {
        final attForPlayer = matrix.data[player.id];
        final att = attForPlayer != null ? attForPlayer[date] : null;
        if (att != null && att.attended) {
          attendedCount++;
        }
      }
    }

    final attendancePercent = totalCount > 0
        ? ((attendedCount / totalCount) * 100).toStringAsFixed(1)
        : '0.0';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 320,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            player.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '#${player.number?.toString() ?? '-'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (player.positions != null &&
                        player.positions!.isNotEmpty)
                      Text(
                        'Posición: ${player.positions!.map((p) => p.name).join(', ')}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Estadísticas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatChip(
                          label: 'Entrenos',
                          value: '$attendedCount/$totalCount',
                        ),
                        _StatChip(
                          label: '% Asistencia',
                          value: '$attendancePercent%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (player.stats != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatChip(
                            label: 'Goles',
                            value: player.stats!.goals.toString(),
                          ),
                          _StatChip(
                            label: 'Asistencias',
                            value: player.stats!.assists.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatChip(
                            label: 'Partidos',
                            value: player.stats!.matchesPlayed.toString(),
                          ),
                          _StatChip(
                            label: 'Tarjetas',
                            value:
                                '${player.stats!.yellowCards}/${player.stats!.redCards}',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _AttendanceMatrix {
  final List<DateTime> dates;
  final Map<int, Map<DateTime, Attendance>> data;

  const _AttendanceMatrix({required this.dates, required this.data});

  const _AttendanceMatrix.empty() : dates = const [], data = const {};
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
