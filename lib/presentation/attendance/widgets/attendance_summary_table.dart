import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/data/datasource/attendance_remote_datasource.dart';
import 'package:football_manager/data/repositories/attendance_repository.dart';
import 'package:football_manager/domain/entities/attendance.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/player_stats.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/presentation/common/widgets/player_name_text.dart';
import 'package:football_manager/presentation/player/widgets/player_avatar.dart';

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
                        dataRowMinHeight: 44,
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
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: PlayerNameText(
                                        player: player,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ),
                                for (final date in matrix.dates)
                                  DataCell(
                                    SizedBox(
                                      width: 80,
                                      child: Center(
                                        child: _buildCell(
                                          matrix,
                                          player.id,
                                          date,
                                        ),
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

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        scheme.primaryContainer.withValues(alpha: 0.75),
                        scheme.surface,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withValues(alpha: 0.16),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: PlayerPhotoRect(
                            player: player,
                            width: 88,
                            height: 118,
                            borderRadius: 14,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PlayerNameText(
                                player: player,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  height: 1.25,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.secondaryContainer
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Dorsal ${player.number?.toString() ?? '—'}',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (player.positions != null &&
                          player.positions!.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.sports_soccer_outlined,
                              size: 20,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                player.positions!.map((p) => p.name).join(', '),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Entrenamientos (fechas de la tabla)',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 18),
                      Text(
                        'Partidos (datos guardados)',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (_) {
                          final s = player.stats ?? const PlayerStats();
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatChip(
                                    label: 'Partidos jugados',
                                    value: s.matchesPlayed.toString(),
                                  ),
                                  _StatChip(
                                    label: 'Como titular',
                                    value: s.timesStarted.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatChip(
                                    label: 'Goles',
                                    value: s.goals.toString(),
                                  ),
                                  _StatChip(
                                    label: 'Asistencias',
                                    value: s.assists.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatChip(
                                    label: 'Minutos',
                                    value: s.minutesPlayed.toString(),
                                  ),
                                  _StatChip(
                                    label: 'Tarjetas (A/R)',
                                    value:
                                        '${s.yellowCards}/${s.redCards}',
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.06 * 255).round()),
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
